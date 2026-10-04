//
//  NearbyBeaconService.swift
//  BuddyDataiOS
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation
import CoreBluetooth
import os
import BuddyDomain
import BuddyDataCore

private let logger = Logger(subsystem: "org.sparcs.soap", category: "NearbyBeaconService")

public enum NearbyBeaconError: Error {
  case bluetoothUnavailable(NearbyBluetoothAuthorization)
}

/// Advertises our nearby token as a single 128-bit service UUID in a legacy,
/// non-connectable advertisement, and scans for everyone else's. Foreground
/// only: CoreBluetooth drops service UUIDs from background advertisements.
///
/// All state lives on `queue`; delegate callbacks arrive there too.
public final class NearbyBeaconService: NSObject, NearbyBeaconServiceProtocol, @unchecked Sendable {
  private let queue = DispatchQueue(label: "org.sparcs.soap.nearby-beacon")

  // Created lazily: making a manager is what shows the Bluetooth prompt, so
  // it must wait until the person asks for nearby discovery.
  private var central: CBCentralManager?
  private var peripheral: CBPeripheralManager?

  private var advertisedUUID: CBUUID?
  private var sightings: AsyncThrowingStream<BeaconSighting, Error>.Continuation?
  private var authorizationObservers: [UUID: AsyncStream<NearbyBluetoothAuthorization>.Continuation] = [:]

  public override init() {
    super.init()
  }

  public var authorization: NearbyBluetoothAuthorization {
    queue.sync { currentAuthorization() }
  }

  public func authorizationUpdates() -> AsyncStream<NearbyBluetoothAuthorization> {
    let (stream, continuation) = AsyncStream.makeStream(
      of: NearbyBluetoothAuthorization.self,
      bufferingPolicy: .bufferingNewest(1)
    )
    let id = UUID()
    queue.async {
      self.authorizationObservers[id] = continuation
      self.makeManagersIfNeeded()
      continuation.yield(self.currentAuthorization())
    }
    continuation.onTermination = { [weak self] _ in
      self?.queue.async { self?.authorizationObservers[id] = nil }
    }
    return stream
  }

  public func start(advertising token: Data) -> AsyncThrowingStream<BeaconSighting, Error> {
    let (stream, continuation) = AsyncThrowingStream.makeStream(of: BeaconSighting.self)
    continuation.onTermination = { [weak self] _ in
      self?.stop()
    }
    queue.async {
      self.stopLocked()
      guard let uuidString = NearbyBeaconUUID.string(for: token) else {
        continuation.finish()
        return
      }
      self.sightings = continuation
      self.advertisedUUID = CBUUID(string: uuidString)
      self.makeManagersIfNeeded()
      self.startIfReady()
    }
    return stream
  }

  public func stop() {
    queue.async { self.stopLocked() }
  }

  // MARK: - Private (on `queue`)

  private func makeManagersIfNeeded() {
    if central == nil {
      central = CBCentralManager(delegate: self, queue: queue, options: [CBCentralManagerOptionShowPowerAlertKey: false])
    }
    if peripheral == nil {
      peripheral = CBPeripheralManager(delegate: self, queue: queue, options: [CBPeripheralManagerOptionShowPowerAlertKey: false])
    }
  }

  private func currentAuthorization() -> NearbyBluetoothAuthorization {
    switch CBManager.authorization {
    case .notDetermined:
      return .notDetermined
    case .denied, .restricted:
      return .denied
    case .allowedAlways:
      break
    @unknown default:
      return .unsupported
    }
    // Until a manager reports its state we can't tell whether the radio is on.
    switch central?.state {
    case .poweredOff:
      return .poweredOff
    case .unsupported:
      return .unsupported
    case .unauthorized:
      return .denied
    default:
      return .allowed
    }
  }

  private func startIfReady() {
    guard sightings != nil else { return }
    if let central, central.state == .poweredOn, !central.isScanning {
      // `nil` services: tokens aren't known in advance. Allowed in the foreground.
      central.scanForPeripherals(
        withServices: nil,
        options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
      )
    }
    if let peripheral, let advertisedUUID, peripheral.state == .poweredOn, !peripheral.isAdvertising {
      // No local name, so the packet is just flags and the one UUID.
      peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [advertisedUUID]])
    }
  }

  private func stopLocked() {
    if central?.isScanning == true { central?.stopScan() }
    if peripheral?.isAdvertising == true { peripheral?.stopAdvertising() }
    advertisedUUID = nil
    let continuation = sightings
    sightings = nil
    continuation?.finish()
  }

  private func stateDidChange() {
    let authorization = currentAuthorization()
    authorizationObservers.values.forEach { $0.yield(authorization) }

    switch authorization {
    case .allowed:
      startIfReady()
    case .poweredOff, .denied, .unsupported:
      let continuation = sightings
      stopLocked()
      continuation?.finish(throwing: NearbyBeaconError.bluetoothUnavailable(authorization))
    case .notDetermined:
      break
    }
  }
}

extension NearbyBeaconService: CBCentralManagerDelegate {
  public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    stateDidChange()
  }

  public func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    guard let sightings else { return }
    let rssi = RSSI.intValue
    // 127 means the reading isn't available.
    guard rssi != 127 else { return }
    let uuids = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? [])
      + (advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] ?? [])
    for uuid in uuids {
      guard let token = NearbyBeaconUUID.token(from: uuid.uuidString) else { continue }
      sightings.yield(BeaconSighting(token: token, rssi: rssi, seenAt: Date()))
    }
  }
}

extension NearbyBeaconService: CBPeripheralManagerDelegate {
  public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    stateDidChange()
  }

  public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    if let error {
      // Others won't see us, but we can still see and ask them.
      logger.error("Advertising failed: \(error.localizedDescription, privacy: .public)")
    }
  }
}
