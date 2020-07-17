//
//  MapManager.swift
//  myPlaces
//
//  Created by Данила on 28.03.2020.
//  Copyright © 2020 Данила. All rights reserved.
//

import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager()
    
    private let regionInMetters:Double = 1_000
    
    private var placeCoordinate: CLLocationCoordinate2D?
    private var directionsArray: [MKDirections] = []
    
    //Проверка доступности сервисов геолокации
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: ()->() ) {
        if CLLocationManager.locationServicesEnabled(){
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAutorization(mapView: mapView, segueIdentifier: segueIdentifier)
            closure()
            
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: {
                self.showAlert(title: "Location Services are Disabled",
                               message: "To enable it go: Settings → Privacy, → Location Services and turn On")
            })
        }
    }
    
    //Проверка авторизации приложения для использования сервисов геолокации
    func checkLocationAutorization(mapView: MKMapView, segueIdentifier: String){
        switch CLLocationManager.authorizationStatus(){
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if segueIdentifier == "getAddress"{ showUserLocation(mapView: mapView) }
        case .denied:
            showAlert(title: "Геолокация отключена", message: "Пройдите в настройки и включите службы геолокации")
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            showAlert(title: "Геолокация отключена", message: "Пройдите в настройки и включите службы геолокации")
            break
        case .authorizedAlways:
            break
        @unknown default:
            print("New place is avelable")
            break
        }
    }
    
    //Фокус карты на местоположении пользователя
    func showUserLocation(mapView: MKMapView) {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMetters,
                                            longitudinalMeters: regionInMetters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    //Построение маршрута
    func getDirections(for mapView: MKMapView, tAD: UILabel, previousLocation: (CLLocation) -> ()){
        
        guard let location = locationManager.location?.coordinate else {
            //Алерт с тем, что локация не определена.
            return
        }
        //Отслеживание пользователя в реальном времени
        locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        
        guard let request = createDirectionsRequest(from: location) else {
            //Алерт! Destination is not found
            return
        }
        
        let directions = MKDirections(request: request)
        resetMapView(mapView: mapView, withNew: directions)
        
        directions.calculate { (response, error) in
            
            if let error = error {
                print(error)
                return
            }
            guard let response = response else {
                //Алерт, что маршрут не доступен, не поступил ответ с сервера
                return
            }
            
            for route in response.routes {
                mapView.addOverlay(route.polyline)//Содержит геометрию всего маршрута
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                let disnance = String(format: "%.1f", route.distance/1000)
                let timeInterval = route.expectedTravelTime
                
                var time = ""
                
                switch timeInterval {
                case 60...3599:
                    time = "\(Int(timeInterval/60)) minutes"
                case 3600...86_399:
                    time = "\(Int(timeInterval/3660)) hours, \((Int(timeInterval)%3600)/60) minutes"
                case 86_400... :
                    time = "\(Int(timeInterval/86_400)) day, \((Int(timeInterval)%86_400)/3600) hours"
                default:
                    time = "\(timeInterval), seconds"
                }
                //                if  timeInterval/86_400 >= 24 {        // Случай в днях
                //                    time = "\(Int(timeInterval/86_400)) day"
                //                } else if (timeInterval/3600) >= 3600{ // Случай в часах
                //                    time = "\(Int(timeInterval/3660)) hours"
                //                } else if (timeInterval/60) >= 1 {  // Случай в минуах
                //                    time = "\(Int(timeInterval/60)) minutes"
                //                } else {
                //                    time = "\(timeInterval), seconds"
                //                }
                
                
                tAD.isHidden = false
                tAD.text = """
                Distance \(disnance) km
                \(time)
                """
                
                //                print("Расстояние до места: \(disnance), км")
                //                print("Время в пути составит: \(Int(timeInterval/60)), минут")
            }
        }
    }
    
    //Создание запроса маршрута
    func createDirectionsRequest(from coordinate:CLLocationCoordinate2D) -> MKDirections.Request? {
        
        guard let destinationCoordinate = placeCoordinate else {return nil}
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation)->()){
        
        guard let location = location else {return}
        let center = getCenterLocation(for: mapView)
        guard center.distance(from: location) > 50 else {return}
        
        closure(center)
    }
    
    func resetMapView (mapView: MKMapView, withNew directions: MKDirections) {
        //Метод для избавления от каких-то текущих маршрутов
        mapView.removeOverlays(mapView.overlays)
        
        directionsArray.append(directions)
        
        let _ = directionsArray.map {$0.cancel()}
        directionsArray.removeAll()
    }
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    //Установка булавки на карту
    func setupPlaceMark(place: LocationDescription, mapView: MKMapView){
        guard let location = place.location else {return}
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location, completionHandler: { (placemarks, error) in
            if let error = error {
                print(error)
                return
            }
            guard let placemarks = placemarks else {return}
            
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = place.name
            annotation.subtitle = place.type
            
            guard let placemarkLocation = placemark?.location else {return}
            
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinate = placemarkLocation.coordinate //Передаём для построения маршрута
            
            mapView.showAnnotations([annotation], animated: true)
            mapView.selectAnnotation(annotation, animated: true)
            
        })
    }
    
    private func showAlert (title: String, message: String){
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        
        alert.addAction(okayAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        
        alertWindow.rootViewController?.present(alert, animated: true)
        
    }
    
    func startTreckingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation)->()){
        
        guard let location = location else {return}
        let center = getCenterLocation(for: mapView)
        guard center.distance(from: location) > 50 else {return}
        
        closure(center)
    }
    
}


