//
//  DateCell.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/8.
//

import UIKit

class DateCell: UITableViewCell {
    
    @IBOutlet weak var lab: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundView?.backgroundColor = .clear
        self.backgroundColor = .clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
