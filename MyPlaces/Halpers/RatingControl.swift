//
//  RatingControl.swift
//  myPlaces
//
//  Created by Данила on 14.03.2020.
//  Copyright © 2020 Данила. All rights reserved.
//

import UIKit

@IBDesignable class RatingControl: UIStackView {

    // MARK: Properties
    // Рейтинг заведения
    var rating = 0{
        didSet {
            updateButtonSelectionState()
        }
    }
    // Кнопки выставления рейтинга
    private var ratingButtons = [UIButton]()
    // Добавляем свойство для кнопки, которое можно изменить в InterfaceBuilder
    @IBInspectable var starSize: CGSize = CGSize(width: 44.0, height: 44.0){
        didSet{
            setupButtons() // Перенастраиваем кнопки
        }
    }
    @IBInspectable var starCount: Int = 5{
        didSet{
            setupButtons()
        }
    }
    
    
    
    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame:frame)
        setupButtons()
    }
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    // MARK: Button Acction
    
    @objc func ratingButtonTapped(button:UIButton){
        guard let index = ratingButtons.firstIndex(of: button) else {return}
        
        //Calculate the rating of the selected button
        let selectedRating = index + 1
        if selectedRating == rating {
            rating = 0
        } else {
            rating = selectedRating
        }
    }
    
    // MARK: Private Methods
    private func setupButtons(){
        
        for button in ratingButtons{
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        ratingButtons.removeAll()
        
        //Load Button image
        let bundle = Bundle(for: type(of: self))
        
        let filledStar = UIImage(named: "filledStar",
                                 in: bundle,
                                 compatibleWith: self.traitCollection)
        
        let emptyStar = UIImage(named: "emptyStar",
                                in: bundle,
                                compatibleWith: self.traitCollection)
        
        let highlightedStar = UIImage(named: "highlightedStar",
                                      in: bundle,
                                      compatibleWith: self.traitCollection)
        
        for _ in 0..<starCount{
        //create the button
        let button = UIButton()
        
        //Set the button Images
            button.setImage(emptyStar, for: .normal)
            button.setImage(filledStar, for: .selected)
            button.setImage(highlightedStar, for: .highlighted)
            button.setImage(highlightedStar, for: [.highlighted, .selected])
        
        //Add Condtraints
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true
        
        //Setup the button action
        button.addTarget(self, action: #selector(ratingButtonTapped(button:)), for: .touchUpInside)
        //Add the button to the stack view
        addArrangedSubview(button)
        //Add the new button on the rating button array
        ratingButtons.append(button)
        }
        updateButtonSelectionState()
    }
    
    private func updateButtonSelectionState(){
        for (index, button) in ratingButtons.enumerated(){
            button.isSelected = index < rating
        }
    }
}
