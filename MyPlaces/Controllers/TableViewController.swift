//
//  TableViewController.swift
//  MyPlaces
//
//  Created by Данила on 09.04.2020.
//  Copyright © 2020 Данила. All rights reserved.
//
import CoreData
import UIKit

class TableViewController: UITableViewController {
    
    var context:NSManagedObjectContext!
    
    // Создаем SearchController
    private let searchController = UISearchController(searchResultsController: nil)
    // Отфильтрованный массив мест
    private var filtredPlaces:[Place] = []
    // Ленивое свойство, проверяющее на пустоту searchBar
    private var searchBarIsEmpty:Bool {
        guard let text = searchController.searchBar.text else {return false}
        return text.isEmpty
    }
    // Заготовка для массива с местами
    var places: [Place] = []
    // Контроллер сортировки – по возрастанию или убыванию
    var ascendingSorted = true
    // Проверка активности searchController
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    // SegmentedControl для выбора способа фильтрации – по имени места или по дате добавления
    @IBOutlet var segmentedControl: UISegmentedControl!
    // Кнопка, отвечающая за способ фильтрации – по возростанию или убыванию
    @IBOutlet var reversedSortingButton: UIBarButtonItem!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getData()
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //производим настройку searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // MARK: - Table view Data Source
    // Функция отвечающая за количество рядов в секции
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filtredPlaces.count
        }
        
        return places.count
    }
    
    // Функция, настраивающая ячейку
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TVCell
        // Трафорет ячейки из базы данных
        let place = isFiltering ? filtredPlaces[indexPath.row]: places[indexPath.row]
        // Настройка полей ячейки
        cell.nameLabel.text = place.name
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        // Добавление фото
        cell.imageOfPlace.image = UIImage(data: place.imageData!)
        
        
        // Rating images
        for (index, star) in cell.ratingImages.enumerated(){
            if index+1 <= Int(place.rating){
                star.image = #imageLiteral(resourceName: "filledStar")
            } else {
                star.image = #imageLiteral(resourceName: "emptyStar")
            }
        }
        
        return cell
    }
    
    // MARK: - Table View Delegate
    // Убираем выделение ранее выбранной ячейки
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // Добавление жеста удаления строки
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard  editingStyle == .delete else { return }

        let place = places[indexPath.row]
        places.remove(at: indexPath.row)
        context.delete(place)
        
        do {
            try context.save()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    //    Другой вариант реализации удаления, устаревший
    //    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    //        let place = places[indexPath.row]
    //        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (_, _) in
    //            StorageManager.deleteObject(place)
    //            tableView.deleteRows(at: [indexPath], with: .automatic)
    //        }
    //        return [deleteAction]
    //    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail"{
            guard let indexPath = tableView.indexPathForSelectedRow else {return}
            
            let place = isFiltering ? filtredPlaces[indexPath.row] : places[indexPath.row]
            
            let newPlaceVC = segue.destination as! NewPlaceViewController
            newPlaceVC.currentPlace = place
        }
    }
    
    // Проверка места из которого мы попадаем на основной экран
    @IBAction func  unwindSegue(_ sender: UIStoryboardSegue){
                    guard let newPlaceVC = sender.source as? NewPlaceViewController else {return}
                    newPlaceVC.savePlaces()
        // Обновление TableView, чтобы показать внесенные изменения
        getData()
        tableView.reloadData()
    }
    
    
    @IBAction func sortSelection(_ sender: UISegmentedControl) {
        sorting()
    }
    
    
    @IBAction func reverdedSorting(_ sender: UIBarButtonItem) {
        ascendingSorted.toggle()
        
        if ascendingSorted {
            reversedSortingButton.image = #imageLiteral(resourceName: "AZ")
        } else {
            reversedSortingButton.image = #imageLiteral(resourceName: "ZA")
        }
        sorting()
    }
    
    private func sorting() {
        if segmentedControl.selectedSegmentIndex == 0 {
            //            places = places.sorted(byKeyPath: "date", ascending: ascendingSorted)
            if ascendingSorted {
                places = places.sorted(by: { (a, b) -> Bool in
                    return a.date! < b.date!
                })
            } else {
                places = places.sorted(by: { (a, b) -> Bool in
                    return a.date! > b.date!
                })
            }
        } else {
            //            places = places.sorted(byKeyPath: "name", ascending: ascendingSorted)
            if ascendingSorted {
                places = places.sorted(by: { (a, b) -> Bool in
                    return a.name!.lowercased() < b.name!.lowercased()
                })
            } else {
                places = places.sorted(by: { (a, b) -> Bool in
                    return a.name!.lowercased() > b.name!.lowercased()
                })
            }
        }
        tableView.reloadData()
    }
    
    private func getData() {
        let fetchRequest:NSFetchRequest<Place> = Place.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            places = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    
}
// Подписываемся под протокол, чтобы производить сортировку
extension TableViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String){
        //Выполнение поиска по полю name и location, а фильтровать мы будем по значению из параметра searchText вне зависимости от регистра символов
        filtredPlaces = places.filter({ (place) -> Bool in
            let loc = place.location
            let name = place.name!
            if loc == nil {
                return name.lowercased().contains(searchText.lowercased())
            } else {
                return (name.lowercased().contains(searchText.lowercased())) || (loc!.lowercased().contains(searchText.lowercased()))
            }
            
            
        })
        tableView.reloadData()
    }
    
}
