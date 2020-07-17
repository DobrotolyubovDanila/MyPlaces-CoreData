//
//  NewPlaceViewController.swift
//  MyPlaces
//
//  Created by Данила on 10.04.2020.
//  Copyright © 2020 Данила. All rights reserved.
//
import CoreData
import UIKit

class NewPlaceViewController: UITableViewController {
    let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    // Переменная, в которую передается информация о месте, если переход осуществлен с TableViewController или заготовка для добавления
    var currentPlace:Place!
    var imageIsChanged = false
    // Изображение нового заведения или пиктограмма
    @IBOutlet var placeImage:UIImageView!
    
    @IBOutlet var saveButton: UIBarButtonItem!
    // Текстовые поля для кастомизации
    @IBOutlet var placeName: UITextField!
    @IBOutlet var locationName: UITextField!
    @IBOutlet var typeName: UITextField!
    // Настраиваем отображение рейтинга
    @IBOutlet var ratingControl:RatingControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Убираем границу под звездами
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,
                                                         y: 0,
                                                         width: tableView.frame.size.width,
                                                         height: 1))
        saveButton.isEnabled = false
        // Отслеживаем пустоту в поле имени места. Наблюдатель?
        placeName.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        setupEditScreen()
    }
    
    // MARK: - Table view data Delegate
    //Обработка выбранной ячейки на экране добавления места
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Реализуем добавление фото
        if indexPath.row == 0 {
            
            let cameraIcon = #imageLiteral(resourceName: "camera")
            let photoLiteral = #imageLiteral(resourceName: "photo")
            
            let actionSheet = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .actionSheet)
            let camera = UIAlertAction(title: "Camera", style: .default, handler: { _ in
                self.chooseImagePicker(source: UIImagePickerController.SourceType.camera)
            })
            camera.setValue(cameraIcon, forKey: "image")
            camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let photo = UIAlertAction(title: "Photo", style: .default, handler: { _ in
                self.chooseImagePicker(source: UIImagePickerController.SourceType.photoLibrary)
            })
            photo.setValue(photoLiteral, forKey: "image")//Добавление изображения всплывающему меню
            photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")//выравнивание слева
            
            let cansel = UIAlertAction(title: "Cancel", style: .cancel)
            
            actionSheet.addAction(camera)
            actionSheet.addAction(photo)
            actionSheet.addAction(cansel)
            
            present(actionSheet, animated:true)
            
        } else {
            view.endEditing(true)
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard
            let identifier = segue.identifier,
            let mapVC = segue.destination as? MapViewController
            else {return}
        
        mapVC.incomeSegueIdentifier = identifier
        mapVC.mapViewControllerDelegate = self
        
        if segue.identifier == "showPlace"{
            mapVC.place.name = placeName.text!
            mapVC.place.location = locationName.text!
            mapVC.place.type = typeName.text!
            mapVC.place.imageData = placeImage.image?.pngData()
        }
    }
    
    
    
}

// MARK: Text Field Delegate
extension NewPlaceViewController: UITextFieldDelegate{
    //Скрываем клавиатуру по нажатию на "Done"
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
    
    @objc private func textFieldChanged(){
        if placeName.text?.isEmpty == false{
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
    
    
    func savePlaces(){
        let image = imageIsChanged ? placeImage.image : #imageLiteral(resourceName: "Питание-2")
        let imageData = image?.pngData()
        
        if currentPlace == nil {
            guard let entity = NSEntityDescription.entity(forEntityName: "Place", in: context!) else { return }
            
            let placeObject = Place(entity: entity, insertInto: context)
            placeObject.date = Date()
            placeObject.imageData = imageData
            placeObject.location = locationName.text
            placeObject.name = placeName.text
            placeObject.rating = Double(ratingControl.rating)
            placeObject.type = typeName.text
            
            do {
                try context!.save()
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
        } else {
            currentPlace.date = Date()
            currentPlace.imageData = imageData
            currentPlace.location = locationName.text
            currentPlace.name = placeName.text
            currentPlace.rating = Double(ratingControl.rating)
            currentPlace.type = typeName.text
            
            do {
                try context!.save()
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        
    }
    
    private func setupEditScreen(){
        if currentPlace != nil {
            setupNavigationBar()
            imageIsChanged = true
            
            guard let data = currentPlace?.imageData, let image = UIImage(data:data) else {return}
            placeName.text = currentPlace?.name
            placeImage.image = image
            locationName.text = currentPlace?.location
            typeName.text = currentPlace?.type
            ratingControl.rating = Int(currentPlace.rating)
            //Кастомизация
            placeImage.contentMode = .scaleAspectFill
        }
    }
    
    private func setupNavigationBar(){
        if let topItem = navigationController?.navigationBar.topItem{
            topItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil )
        }
        navigationItem.leftBarButtonItem = nil
        title = currentPlace?.name
        saveButton.isEnabled = true
    }
    
    @IBAction func cancelAction(_ sender: Any){
        dismiss(animated: true, completion: nil)
    }
    
}


//MARK: Work with image
extension NewPlaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func chooseImagePicker(source: UIImagePickerController.SourceType){
        if UIImagePickerController.isSourceTypeAvailable(source) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true //Редактирование после выбора
            imagePicker.sourceType = source
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey: Any]){
        
        placeImage.image = info[.editedImage] as? UIImage
        placeImage.contentMode = .scaleAspectFill
        placeImage.clipsToBounds = true
        imageIsChanged = true
        dismiss(animated: true, completion: nil)
    }
    
}

extension NewPlaceViewController: MapViewControllerDelegate{
    func getAddress(_ address: String?) {
        locationName.text = address
    }
}
