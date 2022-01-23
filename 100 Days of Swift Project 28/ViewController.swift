//
//  ViewController.swift
//  100 Days of Swift Project 28
//
//  Created by Seb Vidal on 23/01/2022.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {

    @IBOutlet var secretTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotificationCenter()
        setupNavigationBar()
    }

    func setupNotificationCenter() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secretTextView.contentInset = .zero
        } else {
            secretTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secretTextView.scrollIndicatorInsets = secretTextView.contentInset
        
        let selectedRange = secretTextView.selectedRange
        secretTextView.scrollRangeToVisible(selectedRange)
    }
    
    @objc func saveSecretMessage() {
        guard secretTextView.isHidden == false else {
            return
        }
        
        KeychainWrapper.standard.set(secretTextView.text, forKey: "SecretMessage")
        
        secretTextView.resignFirstResponder()
        secretTextView.isHidden = true
        
        title = "Nothing To See Here"
    }
    
    func setupNavigationBar() {
        title = "Nothing To See Here"
    }
    
    @IBAction func authenticateButtonTapped(_ sender: Any) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        self?.showErrorAlert()
                    }
                }
            }
        } else {
            showNoAuthAlert()
        }
    }
    
    func unlockSecretMessage() {
        secretTextView.isHidden = false
        title = "Secret Stuff"
        
        if let text = KeychainWrapper.standard.string(forKey: "SecretMessage") {
            secretTextView.text = text
        }
    }
    
    func showErrorAlert() {
        let alertController = UIAlertController(title: "Authentication Failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alertController, animated: true)
    }
    
    func showNoAuthAlert() {
        let alertController = UIAlertController(title: "Biometry Unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alertController, animated: true)
    }
}

