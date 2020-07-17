//
//  TVCell.swift
//  MyPlaces
//
//  Created by Данила on 10.04.2020.
//  Copyright © 2020 Данила. All rights reserved.
//

import UIKit

class TVCell: UITableViewCell {

        @IBOutlet weak var imageOfPlace: UIImageView!{
        didSet{
            //Customization
            imageOfPlace.layer.cornerRadius = imageOfPlace.frame.size.height/2
            imageOfPlace.clipsToBounds = true
        }
    }
    
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet var ratingImages: [UIImageView]!

}
