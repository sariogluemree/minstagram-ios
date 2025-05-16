//
//  MainTabBarController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 21.04.2025.
//

import UIKit
import PhotosUI

class MainTabBarController: UITabBarController, UITabBarControllerDelegate, PHPickerViewControllerDelegate {
    
    var previousIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTabBar()
        self.delegate = self
    }
    
    private func setupTabBar() {
        
        var controllers: [UIViewController] = []

        let homeSB = UIStoryboard(name: "Main", bundle: nil)
        if let homeNav = homeSB.instantiateViewController(withIdentifier: "FeedNavigationController") as? UINavigationController {
            homeNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "house"), tag: 0)
            controllers.append(homeNav)
        }
        let newPostSB = UIStoryboard(name: "NewPost", bundle: nil)
        if let newPostNav = newPostSB.instantiateViewController(withIdentifier: "NewPostNavigationController") as? UINavigationController {
            newPostNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "plus.app"), tag: 1)
            controllers.append(newPostNav)
        }
        let profileSB = UIStoryboard(name: "Profile", bundle: nil)
        if let profileNav = profileSB.instantiateViewController(withIdentifier: "ProfileNavigationController") as? UINavigationController {
           profileNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "person.crop.circle"), tag: 2)
            let profileVC = profileNav.viewControllers.first as! ProfileViewController
            let activeUser = UserManager.shared.activeUser!
            profileVC.user = activeUser
            controllers.append(profileNav)
        }
        
        self.viewControllers = controllers
        
        tabBar.tintColor = .label
        tabBar.backgroundColor = .systemBackground
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let index = viewControllers?.firstIndex(of: viewController) {
            if index != selectedIndex {
                previousIndex = selectedIndex
            }
            
            if index == 1 {
                var config = PHPickerConfiguration()
                config.filter = .images
                config.selectionLimit = 1

                let picker = PHPickerViewController(configuration: config)
                picker.delegate = self
                present(picker, animated: true)
                
                return false
            }
        }
        return true
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) // Picker'ı kapat

        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { image, error in
            DispatchQueue.main.async {
                if let selectedImage = image as? UIImage {
                    let newPostSB = UIStoryboard(name: "NewPost", bundle: nil)
                    if let newPostNav = newPostSB.instantiateViewController(withIdentifier: "NewPostNavigationController") as? UINavigationController {
                        newPostNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "plus.app"), tag: 1)
                        let newPostVC = newPostNav.viewControllers.first as! PostOptionsViewController
                        newPostVC.selectedImage = selectedImage
                        self.viewControllers?[1] = newPostNav
                        self.selectedIndex = 1
                    }
                }
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
