//
//  ReportProductViewController.swift
//  Tokopedia
//
//  Created by Billion Goenawan on 7/12/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit

@objc(ReportProductViewController)
class ReportProductViewController: UIViewController, UITextViewDelegate, LoginViewDelegate{
    
    var productId: String!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var jenisLaporanLabel: UILabel!
    @IBOutlet weak var deskripsiTextView: UITextView!
    @IBOutlet weak var linkInstructionLabel: UILabel!
    @IBOutlet var downPickerTextField: UITextField!
    @IBOutlet weak var tulisDeskripsiPlaceholderLabel: UILabel!
    @IBOutlet weak var laporkanButton: UIButton!
    
    var downPicker: DownPicker!
    var submitBarButtonItem: UIBarButtonItem!
    var networkManager = TokopediaNetworkManager()
    var reportDataArray : [[String: NSObject]] = []
    var reportLinkUrl: String?
    var userManager = UserAuthentificationManager()
    var selectedReportId: Int!
    var errorAlertView: UIAlertView?
    var successAlertView: UIAlertView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downPickerTextField.enabled = false
        deskripsiTextView.delegate = self
        generateKeyboardNotification()
        setupHiddenObject()
        generateSubmitBarButtonItem()
        setupDownPickerLayout()
        if userManager.isLogin {
            getReportTypeFromAPI()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Laporkan Produk"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTapLaporkanButton(sender: UIButton) {
        var appVersion = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]
        appVersion = appVersion?.stringByReplacingOccurrencesOfString(".", withString: "")
        let webViewVC = WebViewController()
        webViewVC.strURL = reportLinkUrl! + "?flag_app=3&device=ios&app_version=\(appVersion)"
        webViewVC.strTitle = "Laporkan Produk"
        webViewVC.onTapLinkWithUrl = { (url) in
            if (url.absoluteString == "https://www.tokopedia.com/") {
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
        self.navigationController?.pushViewController(webViewVC, animated: true)
    }
    // MARK: KeyboardNotification
    
    func generateKeyboardNotification() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, deskripsiTextView.frame.size.height, 0)
        scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, deskripsiTextView.frame.size.height, 0)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    // MARK: Keyboard Functionality 
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        doneToolbar.barStyle = UIBarStyle.BlackTranslucent
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: #selector(doneButtonAction))
        
        var items: [UIBarButtonItem] = []
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.deskripsiTextView.inputAccessoryView = doneToolbar
    }
    
    func doneButtonAction() {
        self.deskripsiTextView.resignFirstResponder()
    }
    
    // MARK: Layout Setup
    
    func generateSubmitBarButtonItem() {
        self.submitBarButtonItem = UIBarButtonItem(title: "Submit", style: .Plain, target: self, action: #selector(ReportProductViewController.sendReportToServer))
        disableSubmitBarButtonItem()
        self.navigationItem.rightBarButtonItem = submitBarButtonItem
    }
    
    func disableSubmitBarButtonItem() {
        self.submitBarButtonItem.tintColor = UIColor(colorLiteralRed: 228/255, green: 228/255, blue: 228/255, alpha: 1.0)
        self.submitBarButtonItem.enabled = false
    }
    
    func enableSubmitBarButtonItem() {
        self.submitBarButtonItem.tintColor = UIColor(colorLiteralRed: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        self.submitBarButtonItem.enabled = true
    }
    
    func setupHiddenObject() {
        self.tulisDeskripsiPlaceholderLabel.hidden = true
        self.laporkanButton.hidden = true
        self.laporkanButton.cornerRadius = 5
        self.laporkanButton.borderWidth = 1
        self.laporkanButton.borderColor = UIColor(red: 255/255, green: 87/255, blue: 34/255, alpha: 1.0)
        setLinkDescriptionLineSpacing()
        hideDeskripsiForm()
        hideLinkInstruction()
    }
    
    func setLinkDescriptionLineSpacing() {
        let attrString = NSMutableAttributedString(string: self.linkInstructionLabel.text!)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .Center
        attrString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, attrString.length))
        self.linkInstructionLabel.attributedText = attrString
    }
    
    func showDeskripsiForm() {
        self.deskripsiTextView.hidden = false
        showOrHidePlaceholder()
    }
    
    func hideDeskripsiForm() {
        self.deskripsiTextView.hidden = true
        showOrHidePlaceholder()
    }
    
    func hideLinkInstruction() {
        self.linkInstructionLabel.hidden = true
        self.laporkanButton.hidden = true
    }
    
    func showLinkInstruction() {
        self.linkInstructionLabel.hidden = false
        self.laporkanButton.hidden = false
    }
    
    func setupDownPickerLayout() {
        downPickerTextField.layer.borderWidth = 1
        downPickerTextField.layer.cornerRadius = 3
        downPickerTextField.layer.borderColor = UIColor(red: 66/225, green: 181/225, blue: 73/225, alpha: 1.0).CGColor
        downPickerTextField.textColor = UIColor(red: 66/225, green: 181/225, blue: 73/225, alpha: 1.0)
    }
    
    func showOrHidePlaceholder() {
        if self.deskripsiTextView.text == "" && self.deskripsiTextView.hidden == false {
            self.tulisDeskripsiPlaceholderLabel.hidden = false
        } else {
            self.tulisDeskripsiPlaceholderLabel.hidden = true
        }
    }
    
    func showErrorAlertViewWithIsNeedPopViewController(error: String) {
        let stickyAlertView = StickyAlertView(errorMessages: [error], delegate: self)
        stickyAlertView.show()
        
    }
    
    func showSuccessAlertViewWithIsNeedPopViewController() {
        successAlertView = UIAlertView()
        successAlertView?.bk_initWithTitle("Sukses Laporkan Produk", message: "")
        successAlertView?.bk_addButtonWithTitle("OK", handler: { 
            self.navigationController?.popViewControllerAnimated(true)
        })
        successAlertView!.show()
    }
    
    // MARK: API
    
    func getReportTypeFromAPI() {
        networkManager.isUsingHmac = true
        networkManager.requestWithBaseUrl(NSString.v4Url(), path: "/v4/product/get_product_report_type.pl", method: .GET, parameter: ["product_id":productId], mapping: ReportProductGetTypeResponse.mapping(), onSuccess: {(mappingResult, operation) in
                dispatch_async(dispatch_get_main_queue(), { [weak self] in
                    if let weakSelf = self {
                        let result: NSDictionary = (mappingResult as RKMappingResult).dictionary()
                        let reportProductResponse: ReportProductGetTypeResponse = result[""] as! ReportProductGetTypeResponse
                        
                        var reportTitleArray: [String] = []
                        weakSelf.reportDataArray = reportProductResponse.data.list
                        for reportArray in weakSelf.reportDataArray {
                            reportTitleArray.append(reportArray["report_title"]! as! String)
                        }
                        
                        weakSelf.initDownPickerData(reportTitleArray)
                        weakSelf.downPickerTextField.enabled = true
                    }
                })
            }) { (error) in
                dispatch_async(dispatch_get_main_queue(), { [weak self] in
                    if let weakSelf = self {
                        weakSelf.showErrorAlertViewWithIsNeedPopViewController(error.localizedDescription)
                    }
                })
        }
    }
    
    func sendReportToServer() {
        let param : [String:String]! = ["product_id" : self.productId,
                    "report_type" : String(self.selectedReportId),
                    "text_message": self.deskripsiTextView.text,
                    "user_id"     : self.userManager.getUserId()]
        networkManager.isUsingHmac = true
        networkManager.requestWithBaseUrl(NSString.v4Url(), path: "/v4/action/product/report_product.pl", method: .POST, parameter: param, mapping: ReportProductSubmitResponse.mapping(), onSuccess: { (mappingResult, operation) in
                dispatch_async(dispatch_get_main_queue(), { 
                    [weak self] in
                    if let weakSelf = self {
                        let result: NSDictionary = (mappingResult as RKMappingResult).dictionary()
                        let reportProductResponse: ReportProductSubmitResponse = result[""] as! ReportProductSubmitResponse
                        if reportProductResponse.data.is_success == "1" {
                            weakSelf.showSuccessAlertViewWithIsNeedPopViewController()
                        } else {
                            weakSelf.showErrorAlertViewWithIsNeedPopViewController(reportProductResponse.message_error[0])
                        }
                    }
                })
            }) { (error) in
                dispatch_async(dispatch_get_main_queue(), { [weak self] in
                    if let weakSelf = self {
                        weakSelf.showErrorAlertViewWithIsNeedPopViewController(error.localizedDescription)
                    }
                })
        }
    }
    
    // MARK: DownPicker Functionality
    
    func initDownPickerData(reportTitleArray: [String]) {
        var reportTitleArrayWithHardcodedAtIndex0 :[String] = reportTitleArray
        reportTitleArrayWithHardcodedAtIndex0.insert("Pilih Jenis Laporan", atIndex: 0)
        self.downPicker = DownPicker(textField: downPickerTextField, withData: reportTitleArrayWithHardcodedAtIndex0)
        var frame = self.downPicker.getTextField().rightView?.frame
        frame?.size.height = (frame?.size.height)! / 1.5
        frame?.size.width = (frame?.size.width)! / 2
        self.downPicker.getTextField().rightView?.contentMode = .Left
        self.downPicker.getTextField().rightView?.frame = frame!
        self.downPicker.setArrowImage(UIImage(named: "icon_up_down_arrow_green"))
        self.downPicker.selectedIndex = 0
        self.downPicker.shouldDisplayCancelButton = false
        self.downPicker.addTarget(self, action: #selector(ReportProductViewController.didChangeDownPickerValue(_:)), forControlEvents: .ValueChanged)
    }
    
    func didChangeDownPickerValue(downPicker: DownPicker) {
        showOrHidePlaceholder()
        let downPickerSelectedIndex = downPicker.selectedIndex
        if downPickerSelectedIndex > 0 {
            var selectedReportData = reportDataArray[downPickerSelectedIndex-1]
            reportLinkUrl = selectedReportData["report_url"] as? String
            selectedReportId = selectedReportData["report_id"] as? Int
            if selectedReportData["report_response"] == 1 {
                showDeskripsiForm()
                hideLinkInstruction()
                enableSubmitBarButtonItem()
            } else if selectedReportData["report_response"] == 0 {
                hideDeskripsiForm()
                linkInstructionLabel.text = selectedReportData["report_description"] as? String
                setLinkDescriptionLineSpacing()
                showLinkInstruction()
                disableSubmitBarButtonItem()
            }
        } else {
            hideDeskripsiForm()
            hideLinkInstruction()
            disableSubmitBarButtonItem()
        }
    }
    
    // MARK: Text view delegate
    
    func textViewDidBeginEditing(textView: UITextView) {
        self.tulisDeskripsiPlaceholderLabel.hidden = true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        showOrHidePlaceholder()
    }
    
    // MARK: Login View delegate 
    
    func redirectViewController(viewController: AnyObject!) {
        
    }
}
