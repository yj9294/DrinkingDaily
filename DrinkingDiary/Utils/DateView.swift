//
//  DateView.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/8.
//

import UIKit

protocol DateViewDelegate : NSObjectProtocol {
    func completion(time: String)
    func cancel()
}

class DateView: UIView {

    weak var delegate: DateViewDelegate?
    var selectedHours = 0
    var selectedMine = 0
    var hours:[Int] = Array(0..<13)
    var minutes: [Int] = Array(0..<60)
    @IBOutlet weak var hourTableView: UITableView!
    @IBOutlet weak var minuteTableView: UITableView!
    @IBOutlet weak var amLabel: UILabel!
    @IBOutlet weak var pmLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        hours.append(contentsOf: Array(1..<12))
        hourTableView.register(UINib(nibName: "DateCell", bundle: .main), forCellReuseIdentifier: "DateCell")
        minuteTableView.register(UINib(nibName: "DateCell", bundle: .main), forCellReuseIdentifier: "DateCell")
    }
    
    @IBAction func saveAction() {
        let str = String(format: "%02d:%02d", selectedHours, selectedMine)
        delegate?.completion(time: str)
    }
    
    @IBAction func cancelAction() {
        delegate?.cancel()
    }
}

extension DateView: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == hourTableView {
            return hours.count
        } else {
            return minutes.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DateCell", for: indexPath)
        if let cell = cell as? DateCell {
            if tableView == hourTableView {
                cell.lab.text = "\(hours[indexPath.row]) h"
            } else {
                cell.lab.text = "\(minutes[indexPath.row]) m"
            }
        }
        if tableView == hourTableView {
            let isPM = indexPath.row > 12
            pmLabel.textColor = UIColor(named: isPM ? "#1872B4" : "#B8BABD")
            amLabel.textColor = UIColor(named: !isPM ? "#1872B4" : "#B8BABD")
            selectedHours = indexPath.row
        } else {
            selectedMine = indexPath.row
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 107.0
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let hourCell = hourTableView.visibleCells.first {
            selectedHours = hourTableView.indexPath(for: hourCell)?.row ?? 0
        }
        if let mineCell = minuteTableView.visibleCells.first {
            selectedMine = minuteTableView.indexPath(for: mineCell)?.row ?? 0
        }
    }
    
}
