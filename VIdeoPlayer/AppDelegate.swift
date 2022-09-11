//
//  AppDelegate.swift
//  VIdeoPlayer
//
//  Created by LanceMacBookPro on 3/26/22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        
        let vc = ViewController()
        let navVC = UINavigationController(rootViewController: vc)
        
        window?.rootViewController = navVC
        
        return true
    }
}
