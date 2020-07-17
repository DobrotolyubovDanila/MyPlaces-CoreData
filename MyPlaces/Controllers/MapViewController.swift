//
//  MapViewController.swift
//  myPlaces
//
//  Created by Данила on 15.03.2020.
//  Copyright © 2020 Данила. All rights reserved.
//
import MapKit
import UIKit
import CoreLocation

protocol MapViewControllerDelegate {
    func getAddress(_ address:String?)
}
//Расширение протоколов создается с целью сделать внедренные в него методы опциональными


class MapViewController: UIViewController {
    
    @IBOutlet var timeAndDistance: UILabel!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mapPinImage: UIImageView!
    @IBOutlet var doneButton:UIButton!
    @IBOutlet var addressLable:UILabel!
    @IBOutlet var goButton:UIButton!
    
    let mapManager = MapManager()

    var mapViewControllerDelegate: MapViewControllerDelegate?
    
    var place = LocationDescription()
    
    var image = UIImage()
    
    let annotationIdentifier = "annotationIdentifier"
    
    var incomeSegueIdentifier = ""
    
    var previousLocation:CLLocation?{
        didSet {
            mapManager.startTrackingUserLocation(for: mapView,
                                                 and: previousLocation) { (currentLocation) in
                                                    
                                                    self.previousLocation = currentLocation
                                                    
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                        self.mapManager.showUserLocation(mapView: self.mapView)
                                                    }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupMapView()
        addressLable.text = ""
    }
    
    @IBAction func centerViewInUserLocation() {
        mapManager.showUserLocation(mapView: mapView)
    }
    
    @IBAction func closeVC(){
        dismiss(animated: true, completion: nil)
    }

    private func setupMapView(){
        
        goButton.isHidden = true
        
        mapManager.checkLocationServices(mapView: mapView, segueIdentifier: incomeSegueIdentifier) {
            mapManager.locationManager.delegate = self
        }
        
        if incomeSegueIdentifier == "showPlace"{
            mapManager.setupPlaceMark(place: place, mapView: mapView)
            mapPinImage.isHidden = true
            addressLable.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
    
    
    private func setupLocationManager(){
        mapManager.locationManager.delegate = self
        mapManager.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    
    @IBAction func goButtonPressed() {
        
        mapManager.getDirections(for: mapView, tAD: timeAndDistance) { (location) in
            self.previousLocation = location
        }
    }
    
    @IBAction func doneButtonPressed(){
        mapViewControllerDelegate?.getAddress(addressLable.text)
        //Когда мы будем делать реализацию данного метода в классе NewPlaceViewContoller его параметр address будет содержать данный текст – адрес
        dismiss(animated: true, completion: nil)
    }
}


extension MapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else { return nil }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        
        if let imageData = place.imageData {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data:imageData)
            annotationView?.rightCalloutAccessoryView = imageView
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = mapManager.getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if incomeSegueIdentifier == "showPlace" && previousLocation != nil{
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.mapManager.showUserLocation(mapView: self.mapView)
            }
        }
        
        geocoder.cancelGeocode() // Метод вроде как для отмены кучи последовательных действий и освобождения ресурсов
        
        geocoder.reverseGeocodeLocation(center, completionHandler: {(placemarks, error) in
            
            if let error = error{
                print(error)
                return
            }
            
            guard let placemarks = placemarks else {return}
            
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            let town = placemark?.locality
            
            DispatchQueue.main.async {
                
                if streetName != nil && buildNumber != nil && town != nil{
                self.addressLable.text = "\(town!), \(streetName!), \(buildNumber!)"
                } else if streetName != nil && town != nil{
                    self.addressLable.text = "\(town!), \(streetName!)"
                } else {
                    self.addressLable.text = ""
                }
            }
        })
    }
    
    //Метод, чтобы подсветить все маршруты определенным цветом
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline) //Рендеринг наложения, сделанного ранее
        
        renderer.strokeColor = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
        
        return renderer
    }
    
}

extension MapViewController:CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapManager.checkLocationAutorization(mapView: mapView, segueIdentifier: incomeSegueIdentifier)
    }
}
