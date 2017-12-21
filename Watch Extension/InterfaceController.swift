//
//  InterfaceController.swift
//  IoT Extension
//
//  Created by Matheus Pereiradarocha on 10/21/17.
//  Copyright © 2017 Matheus Pereiradarocha. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation
import MapKit
import UIKit
class InterfaceController: WKInterfaceController,CLLocationManagerDelegate {
    // TODO: realizar captacao da localizacao em background de x em x minutos
    @IBOutlet var mapa: WKInterfaceMap!
    var locman : CLLocationManager!
    private var startTime: Date? //An instance variable, will be used as a previous location time.
    var origem : CLLocationCoordinate2D!
    var destino : CLLocationCoordinate2D!
    let separatorLine = "\n-----------------\n"
    
    
    var coapClient: SCClient!
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let client = SCClient(delegate: self)
        client.sendToken = true
        client.autoBlock1SZX = 2
        self.coapClient = client
        self.locman = CLLocationManager()
        // detailValue represents the type of message: GET, POST ,...
        self.locman.delegate = self
        self.locman.desiredAccuracy = kCLLocationAccuracyBest // You can change the locaiton accuary here.
        self.locman.startUpdatingLocation()
//        print(locman)
//        locman.requestWhenInUseAuthorization()
//        self.locman.requestLocation()
//        print(self.locman.location)
//        print(selflocman.requestLocation())
        print(locman.location?.coordinate.latitude ?? "sem latitudee")
        let lat = locman.location?.coordinate.latitude ?? 0.0
        let lon = locman.location?.coordinate.longitude ?? 0.0
        let idDispositivo = WKInterfaceDevice.current().hashValue
//        let localizacao = "\(lat),\(lon)"
        let localizacao = "\(idDispositivo),\(lat),\(lon)"
        print(localizacao)
        let m = SCMessage(code: SCCodeValue(classValue: 0, detailValue: 01)!, type: .confirmable, payload: localizacao.data(using: String.Encoding.utf8))
        
//        //        if let stringData = uriPathTextField.text?.data(using: String.Encoding.utf8) {
//        // FUNCIONANDO PARA O NODEJS
//        m.addOption(SCOption.uriPath.rawValue, data: localizacao.data(using: String.Encoding.utf8)!)
//        //        }
        m.addOption(SCOption.uriPath.rawValue, data: "basic".data(using: String.Encoding.utf8)!)

        
        if  let port = UInt16("5683") {
            let hostString = "localhost"
            coapClient.sendCoAPMessage(m, hostName:hostString,  port: port)
        }
        
        //Default values, change if you want
        //        hostTextField.text = "coap.me"
        //        portTextField.text = ""
        // Configure interface objects here.
        
        
        let mylocation : CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, lon)
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let region = MKCoordinateRegion(center: mylocation, span: span)
        self.mapa.setRegion(region)
        self.mapa.addAnnotation(mylocation, with: .red)
    

    }
    
    @IBAction func obterDestino() {
        // ao ser clicado var enviado um get para o servidor
        // o servidor vai pegar a ultima localizacao do aparelho e calcular qual o servico mais proximo
        // a proximidade vai ser calculada baseada em distancia e prioridade
        // por exemplo o servico 1 esta mais proximo que o servico 2, mas ele tem uma prioridade menor
        // tera q ser realizado um calculo com peso para prioridades e distancia para calcular o servico destino
        // esse vai enviar para o aparelho o destino do servico a ser executado
        // no mapa sera criado um novo pinpoint com o endereco destino passado pelo servidor
        // o cliente vai poder visualizar sua localicazacao em tempo real e o destino
        // quando terminar de executar o servico, pode pedir um novo servico
        let lat = locman.location?.coordinate.latitude ?? 0.0
        let lon = locman.location?.coordinate.longitude ?? 0.0
        let idDispositivo = WKInterfaceDevice.current().hashValue
//        let localizacao: [String: Any] = [
//            "idDispositivo": idDispositivo,
//            "latitude" : lat,
//            "longitude" : lat
//        ]
//        var localizacao = (idDispositivo: idDispositivo, latitude: lat)
        let localizacao = "\(idDispositivo),\(lat),\(lon)"
//        print(localizacao)
        origem = CLLocationCoordinate2DMake(lat, lon)
        let m = SCMessage(code: SCCodeValue(classValue: 0, detailValue: 01)!, type: .confirmable, payload: localizacao.data(using: String.Encoding.utf8))
        m.addOption(SCOption.uriPath.rawValue, data: "storage".data(using: String.Encoding.utf8)!)
        if  let port = UInt16("5683") {
            let hostString = "localhost"
            coapClient.sendCoAPMessage(m, hostName:hostString,  port: port)
        }
        
//        let artwork = Artwork(title: "King David Kalakaua",
//                              locationName: "Waikiki Gateway Park",
//                              discipline: "Sculpture",
//                              coordinate: CLLocationCoordinate2D(latitude: 21.283921, longitude: -157.831661))
//        let coordinate =  CLLocationCoordinate2D(latitude: -3.795765, longitude: -38.492164)
//
//        mapa.addAnnotation(coordinate, with: .purple)
//        mapa.addAnnotation(artwork)
        
    }
    func UnoDirections(destino: CLLocationCoordinate2D){
        var coordinates = [CLLocationCoordinate2D]()
        coordinates += [origem]
        coordinates += [destino]
//        coordinates += [ChicagoCenterCoordinate().coordinate] //State and Washington
//        coordinates += [CLLocationCoordinate2D(latitude: 41.8924847, longitude: -87.6280187)]
//        coordinates += [restaurants[10].coordinate] //Uno's
//        Mkpolyli
//        let path = MK (coordinates: &
//        coordinates, count: coordinates.count)
//        mapa.addOverlay(path)
        let coordinate = CLLocationCoordinate2DMake(destino.latitude,destino.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
        mapItem.name = "Target location"
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("MUDOU")
        guard let loc = locations.last else { return }

        let time = loc.timestamp

        guard let startTime = startTime else {
            self.startTime = time // Saving time of first location, so we could use it to compare later with second location time.
            return //Returning from this function, as at this moment we don't have second location.
        }

        let elapsed = time.timeIntervalSince(startTime) // Calculating time interval between first and second (previously saved) locations timestamps.

        if elapsed > 30 { //If time interval is more than 30 seconds
            print("Upload updated location to server")
            print(loc)
            //updateUser(location: loc) //user function which uploads user location or coordinate to server.

            self.startTime = time //Changing our timestamp of previous location to timestamp of location we already uploaded.

        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locman.requestLocation()
        }
    }

}

extension InterfaceController: SCClientDelegate {
    func swiftCoapClient(_ client: SCClient, didReceiveMessage message: SCMessage) {
        var payloadstring = ""
        if let pay = message.payload {
            if let string = NSString(data: pay as Data, encoding:String.Encoding.utf8.rawValue) {
                payloadstring = String(string)
                let coordenada = payloadstring.components(separatedBy: ",")
                if let lat = Double(coordenada[0]), let lon = Double(coordenada[1]){
                    destino =  CLLocationCoordinate2D(latitude: lat, longitude: lon )
                    self.mapa.addAnnotation(destino, with: .green)
                    UnoDirections(destino: destino)
//                    ope
                    
                }
            }
        }
        let firstPartString = "Message received from \(message.hostName ?? "") with type: \(message.type.shortString())\nwith code: \(message.code.toString()) \nwith id: \(message.messageId ?? 0)\nPayload: \(payloadstring)\n"
        var optString = "Options:\n"
        for (key, _) in message.options {
            var optName = "Unknown"
            
            if let knownOpt = SCOption(rawValue: key) {
                optName = knownOpt.toString()
            }
            
            optString += "\(optName) (\(key))\n"
        }
//        print(message.)
        //        textView.text = separatorLine + firstPartString + optString + separatorLine + textView.text
        print(separatorLine + firstPartString + optString + separatorLine)
    }
    
    func swiftCoapClient(_ client: SCClient, didFailWithError error: NSError) {
        //        textView.text = "Failed with Error \(error.localizedDescription)" + separatorLine + separatorLine + textView.text
        print("Failed with Error \(error.localizedDescription)" + separatorLine + separatorLine)
    }
    
    func swiftCoapClient(_ client: SCClient, didSendMessage message: SCMessage, number: Int) {
        //        textView.text = "Message sent (\(number)) with type: \(message.type.shortString()) with id: \(message.messageId)\n" + separatorLine + separatorLine + textView.text
        print("Message sent (\(number)) with type: \(message.type.shortString()) with id: \(message.messageId)\n" + separatorLine + separatorLine)
    }
    
}







