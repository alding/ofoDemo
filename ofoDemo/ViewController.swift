//
//  ViewController.swift
//  ofoDemo
//
//  Created by icecream on 2017/7/28.
//  Copyright © 2017年 何可. All rights reserved.
//

import UIKit
import SWRevealViewController

class ViewController: UIViewController,MAMapViewDelegate,AMapSearchDelegate {
    var mapView : MAMapView!
    var search : AMapSearchAPI!
    var pin : MyPinAnnotation!
    var pinView : MAAnnotationView!
    var nearBySraech = true
    
    
    @IBOutlet weak var panelView: UIView!
    @IBAction func locationBtnTap(_ sender: UIButton) {
        searchBikeNearby()
    }
    
    //搜索小黄车请求
    func searchBikeNearby() {
        nearBySraech = true
        searchCustomLocation(mapView.userLocation.coordinate)
    }
    
    func searchCustomLocation(_ center:CLLocationCoordinate2D)  {
        let requset = AMapPOIAroundSearchRequest()
        requset.location = AMapGeoPoint.location(withLatitude: CGFloat(center.latitude), longitude: CGFloat(center.longitude))
        requset.keywords = "餐馆"
        requset.radius = 500
        requset.requireExtension = true
        
        search.aMapPOIAroundSearch(requset)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView = MAMapView(frame: view.bounds)
        view.addSubview(mapView)
        mapView.delegate = self
        mapView.zoomLevel = 17
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        search = AMapSearchAPI()
        search.delegate = self

        
        view .bringSubview(toFront: panelView)
        self.navigationItem.titleView = UIImageView (image: #imageLiteral(resourceName: "ofoLogo_32x17_"))
        self.navigationItem.rightBarButtonItem?.image = #imageLiteral(resourceName: "rightTopImage_20x20_").withRenderingMode(.alwaysOriginal)
        self.navigationItem.leftBarButtonItem?.image = #imageLiteral(resourceName: "leftTopImage_20x20_").withRenderingMode(.alwaysOriginal)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style: .plain, target: nil, action: nil)
        
        if let revealVC = revealViewController() {
            revealVC.rearViewRevealWidth = 280
            navigationItem.leftBarButtonItem?.target = revealVC
            navigationItem.leftBarButtonItem?.action = #selector(SWRevealViewController.revealToggle(_:))
            view.addGestureRecognizer(revealVC.panGestureRecognizer())
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - 大头针动画
    func pinAnimation() {
        //坠落效果，y轴加位移.
        let endFrame = pinView.frame
        
        pinView.frame = endFrame.offsetBy(dx: 0, dy: -15)
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 0, options: [], animations: { 
            self.pinView.frame = endFrame
        }, completion: nil)
    }

    
    // MARK: - MapView Delegate
    
    /// 目标视图动画效果
    ///
    /// - Parameters:
    ///   - mapView: mapView
    ///   - views: 标视图动画效果
    func mapView(_ mapView: MAMapView!, didAddAnnotationViews views: [Any]!) {
        let aViews = views as!  [MAAnnotationView]
        
        for aView in aViews {
            guard aView.annotation is MAPointAnnotation else {
                continue
            }
            aView.transform  = CGAffineTransform(scaleX: 0, y: 0)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: [], animations: {
                aView.transform = .identity
            }, completion: nil)

        }
        
    }
    
    /// 用户移动地图的交互
    ///
    /// - Parameters:
    ///   - mapView: mapView
    ///   - wasUserAction: 用户是否移动
    func mapView(_ mapView: MAMapView!, mapDidMoveByUser wasUserAction: Bool) {
        if wasUserAction{
            pin.isLockedToScreen = true
            pinAnimation()
            searchCustomLocation(mapView.centerCoordinate)
        }
    }
    
    /// 地图初始化完成后
    ///
    /// - Parameter mapView: mapView
    func mapInitComplete(_ mapView: MAMapView!) {
        pin = MyPinAnnotation()
        pin.coordinate = mapView.centerCoordinate
        pin.lockedScreenPoint = CGPoint(x: view.bounds.width/2, y: view.bounds.height/2)
        pin.isLockedToScreen = true
        
        mapView.addAnnotation(pin)
        mapView.showAnnotations([pin], animated: true)
    }
    
    /// 自定义大头针视图
    ///
    /// - Parameters:
    ///   - mapView: mapView
    ///   - annotation: 标注
    /// - Returns: 大头针视图
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        //用户定义的位置，不需要自定义
        if annotation is MAUserLocation {
            return nil;
        }
        
        if annotation is MyPinAnnotation {
            let reuseid = "anchor"
            var av = mapView.dequeueReusableAnnotationView(withIdentifier: reuseid)
            
            if av == nil {
                av = MAPinAnnotationView(annotation: annotation, reuseIdentifier: reuseid)
            }
            
            av?.image = #imageLiteral(resourceName: "homePage_wholeAnchor_24x37_")
            
            av?.canShowCallout = false
            
            pinView = av
            return av
        }
        
        let reuseid = "myid"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseid) as? MAPinAnnotationView
        
        if annotationView == nil {
            annotationView = MAPinAnnotationView(annotation: annotation, reuseIdentifier: reuseid)
        }
        
        if annotation.title == "正常可用"{
            annotationView?.image = #imageLiteral(resourceName: "HomePage_nearbyBike_50x50_")
        }else{
            annotationView?.image = #imageLiteral(resourceName: "HomePage_nearbyBikeRedPacket_45x45_")
        }
        
        annotationView?.canShowCallout = true

        annotationView?.animatesDrop = true
        
        return annotationView

    }
    
    // MARK: - AMap Search Delegate
    //搜索周边完成后的处理
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        
        guard response.count > 0 else {
            print("周边没有小黄车")
            return
        }
        
        var annotations : [MAPointAnnotation] = []
        
        annotations = response.pois.map{
            let annotation  = MAPointAnnotation()
            
            annotation.coordinate = CLLocationCoordinate2D(latitude:CLLocationDegrees($0.location.latitude),longitude:CLLocationDegrees($0.location.longitude))
            
            if $0.distance<200 {
                annotation.title = "红包区域内开锁任意小黄车"
                annotation.subtitle = "骑行1分钟可获得现金红包"
            }else{
                annotation.title = "正常可用"
            }
            
            return annotation
        }
        
        mapView.addAnnotations(annotations)
        if nearBySraech {
            mapView.showAnnotations(annotations, animated: true)
            nearBySraech = !nearBySraech
        }

    }


}

