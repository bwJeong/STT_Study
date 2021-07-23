//
//  MyTableViewCell.swift
//  SpeechToTextTest
//
//  Created by Byungwook Jeong on 2021/07/23.
//

import UIKit

class MyTableViewCell: UITableViewCell {
    @IBOutlet weak var myLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
