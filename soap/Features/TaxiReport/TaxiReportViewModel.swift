//
//  TaxiReportViewModel.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Observation

@Observable
class TaxiReportViewModel {
  // MARK: - View Properties
  var selectedUser: TaxiParticipant?
  var selectedReason: TaxiReport.Reason?
  var etcReasonDetail = ""
}
