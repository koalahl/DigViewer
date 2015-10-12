//
//  MapGeometry.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/12.
//  Copyright © 2015年 opiopan. All rights reserved.
//

import UIKit
import MapKit

class MapGeometry: NSObject {
    let latitude : Double
    let longitude : Double
    let viewLatitude : Double
    let viewLongitude : Double
    
    let spanLatitude : Double
    let spanLongitude : Double
    let spanLatitudeMeter : Double
    let spanLongitudeMeter : Double
    
    let centerCoordinate : CLLocationCoordinate2D
    let photoCoordinate : CLLocationCoordinate2D
    
    let mapSpan : MKCoordinateSpan
    let cameraAltitude : Double
    let cameraHeading : Double
    let cameraTilt : Double
    
    init(meta: [NSObject : AnyObject]!){
        latitude = (meta[DVRCNMETA_LATITUDE] as! Double?)!
        longitude = (meta[DVRCNMETA_LONGITUDE] as! Double?)!
        spanLatitude = (meta[DVRCNMETA_SPAN_LATITUDE] as! Double?)!
        spanLongitude = (meta[DVRCNMETA_SPAN_LONGITUDE] as! Double?)!
        spanLatitudeMeter = spanLatitude * 111000;
        spanLongitudeMeter = spanLongitude * fabs(cos(latitude)) * 111000;
        let heading = meta[DVRCNMETA_HEADING] as! Double?
        
        let OFFSET_RATIO = 0.3
        let deltaLat = spanLatitude * OFFSET_RATIO
        let compensating = fabs(cos(latitude / 180 * M_PI))
        let deltaLng = compensating == 0 ? deltaLat : deltaLat / compensating

        if heading != nil {
            viewLatitude = latitude + deltaLat * cos(heading! / 180.0 * M_PI)
            viewLongitude = longitude + deltaLng * sin(heading! / 180.0 * M_PI)
            cameraHeading = heading!
            cameraTilt = 60
        }else{
            viewLatitude = latitude
            viewLongitude = longitude
            cameraHeading = 0
            cameraTilt = 50
        }

        photoCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
        centerCoordinate = CLLocationCoordinate2DMake(viewLatitude, viewLongitude)
        mapSpan = MKCoordinateSpanMake(spanLatitude, spanLongitude)

        cameraAltitude = max(spanLatitudeMeter, spanLongitudeMeter) * 1.87 * cos(cameraTilt / 180 * M_PI)
    }
}
