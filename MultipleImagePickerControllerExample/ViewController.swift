//
//  ViewController.swift
//  MultipleImagePickerControllerExample
//
//  Created by Alessandro Maroso on 06/12/2017.
//  Copyright © 2017 membersheep. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var label: UILabel!
    
    let pickerController = MultipleImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerController.delegate = self
    }

    @IBAction func buttonTapped(_ sender: Any) {
        self.present(pickerController, animated: true, completion: nil)
    }
    
}

extension ViewController: MultipleImagePickerControllerDelegate {
    func multipleImage(picker: MultipleImagePickerController, didFinishPicking images: [UIImage]) {
        label.text = "picked \(images.count) images"
        pickerController.dismiss(animated: true, completion: nil)
    }
    
    func multipleImagePickerDidCancel(picker: MultipleImagePickerController) {
        label.text = "picking cancelled"
        pickerController.dismiss(animated: true, completion: nil)
    }
}
