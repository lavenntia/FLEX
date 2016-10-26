//
//  MessageViewController.swift
//  Tokopedia
//
//  Created by Tonito Acen on 10/12/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class MessageViewController: JSQMessagesViewController {
    
    var messageTitle = ""
    var messageId: String!
    var onMessagePosted: ((String) -> Void)!
    var labelColorsCollection = [
        "1" : UIColor(red: 248.0/255.0, green: 148.0/255.0, blue: 6.0/255.0, alpha: 1.0), //admin
        "2" : UIColor(red: 70.0/255.0, green: 136.0/255.0, blue: 71.0/255.0, alpha: 1.0), //pengguna
        "3" : UIColor(red: 185.0/255.0, green: 74.0/255.0, blue: 72.0/255.0, alpha: 1.0), //penjual
        "4" : UIColor(red: 42.0/255.0, green: 180.0/255.0, blue: 194.0/255.0, alpha: 1.0), //pembeli
        "5" : UIColor(red: 153.0/255.0, green: 153.0/255.0, blue: 153.0/255.0, alpha: 1.0) // system
    ]
    
    private var messages = [JSQMessage]()
    private var avatars = Dictionary<String, JSQMessagesAvatarImage>()
    private var userLabelColors = Dictionary<String, UIColor>()
    
    private var outgoingBubbleImageView: JSQMessagesBubbleImage!
    private var incomingBubbleImageView: JSQMessagesBubbleImage!
    private var nextPage: String?
    
    lazy var fetchMessageManager : TokopediaNetworkManager = {
       var manager = TokopediaNetworkManager()
        manager.isUsingHmac = true
        return manager
    }()
    
    lazy var sendMessageManager : TokopediaNetworkManager = {
        var manager = TokopediaNetworkManager()
        manager.isUsingHmac = true
        return manager
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        inputToolbar.contentView.leftBarButtonItem = nil
        title = messageTitle
        setupBubbles()
        fetchMessages("1")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    //MARK: JSQMessageDataSource
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        
        if(message.senderId != self.senderId) {
            return NSAttributedString(string: message.senderDisplayName, attributes: [NSForegroundColorAttributeName : userLabelColors[message.senderId]!, NSFontAttributeName : UIFont.microThemeMedium()])
        }
        
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            return 0
        } else {
            return 20
        }
    }
    
   
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.whiteColor()
        } else {
            cell.textView!.textColor = UIColor.blackColor()
        }
        
        cell.textView!.delegate = self
        cell.textView!.linkTextAttributes = [NSForegroundColorAttributeName : UIColor.blueColor(), NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue]
        
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, atIndexPath indexPath: NSIndexPath!) {
        let message = messages[indexPath.item]
        
        let controller = NavigateViewController()
        controller.navigateToProfileFromViewController(self, withUserID: message.senderId)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        
        return avatars[message.senderId]
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        self.fetchMessages(self.nextPage)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        
        if(indexPath.item == 0) {
            return 20
        }
        
        if(indexPath.item - 1 > 0) {
            let message = messages[indexPath.item]
            let previousMessage = self.messages[indexPath.item - 1]
            if(message.date.timeIntervalSinceDate(previousMessage.date) / (24 * 60 * 60) > 1) {
                return 20
            }
        }
        
        return 0
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        
        if(indexPath.item == 0) {
            return NSAttributedString.init(string: JSQMessagesTimestampFormatter.sharedFormatter().relativeDateForDate(message.date))
        }
        
        if(indexPath.item - 1 > 0) {
            let previousMessage = self.messages[indexPath.item - 1]
            if(message.date.timeIntervalSinceDate(previousMessage.date) / (24 * 60 * 60) > 1) {
                return NSAttributedString.init(string: JSQMessagesTimestampFormatter.sharedFormatter().relativeDateForDate(message.date))
            }
        }
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 20
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        
        return NSAttributedString.init(string: JSQMessagesTimestampFormatter.sharedFormatter().timeForDate(message.date))
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        let message = JSQMessage(senderId: self.senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        self.messages.append(message)
        
        self.finishSendingMessageAnimated(true)
        
        sendMessageManager .
            requestWithBaseUrl(NSString.kunyitUrl(),
                               path: "/v1/message/reply",
                               method: .POST,
                               parameter: ["reply_message" : text, "message_id" : self.messageId],
                               mapping: InboxMessageAction.mapping(),
                               onSuccess: { [unowned self] (result, operation) in
                                
                                    let result = result.dictionary()[""] as! InboxMessageAction
                                    if(result.data.is_success == "1") {
                                        self.onMessagePosted(text)
                                    } else {
                                        self.receiveErrorSendMessage(result.message_error)
                                    }
                               },
                               onFailure: { (error) in
                                    self.receiveErrorSendMessage(["Mohon maaf terjadi kesalahan pada saat mengirim pesan. Silakan ulangi beberapa saat kemudian."])
                               }
                
        )
    }
    
    private func receiveErrorSendMessage(errors: [AnyObject]) {
        let stickyAlert = StickyAlertView(errorMessages: errors, delegate: self)
        stickyAlert .show()
        self.messages.removeLast()
        self.finishSendingMessageAnimated(true)
    }
    
    //MARK: TextView Delegate
    override func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        var urlString : String!
        if(URL.scheme == "http" || URL.scheme == "https") {
            if(URL.host == "www.tokopedia.com") {
                urlString = URL.absoluteString!
            } else {
                urlString = "https://tkp.me/r?url=\(URL.absoluteString!.stringByReplacingOccurrencesOfString("*", withString: "."))"
            }
            
            self.openWebViewWithUrl(urlString)
            
            return false
        }
        
        return true
    }
    
    //MARK: Bubble Setup
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    //MARK: Network
    private func fetchMessages(page: String!) {
        fetchMessageManager .
            requestWithBaseUrl(
                NSString.kunyitUrl(),
                path: "/v1/message/detail",
                method: .GET,
                parameter: ["message_id" : messageId, "page" : page, "per_page" : "10"],
                mapping: InboxMessageDetail.mapping(),
                onSuccess: { [unowned self] (result, operation) in
                    
                    let result = result.dictionary()[""] as! InboxMessageDetail
                    if((result.message_error == nil)) {
                        self.didReceiveMessages(result.result.list as! [InboxMessageDetailList])
                        
                        self.showLoadEarlierMessagesHeader = result.result.paging.isShowNext
                        self.nextPage = result.result.paging.uriNext.valueForKey("page")
                    }
                    
                },
                onFailure: { (error) in
            
                }
        )
    }
    
    private func didReceiveMessages(messages: [InboxMessageDetailList]) {
        messages.forEach({ (message) in
            let message = message

            let dateString = message.message_reply_time.formatted
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            
            let dateObj = dateFormatter.dateFromString(dateString)!
            let messageReply = NSString.extracTKPMEUrl(message.message_reply)
            
            if(message.user_id == self.senderId) {
                self.addMessage(self.senderId, text: messageReply , senderName: "",date: dateObj)
            } else {
                self.addMessage(message.user_id, text: messageReply, senderName: "\(message.user_label) - \(message.user_name)", date: dateObj)
                let image = UIImage(data: NSData(contentsOfURL: NSURL(string: message.user_image)!)!)
                
                avatars[message.user_id] = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: UInt(collectionView.collectionViewLayout.incomingAvatarViewSize.width))
                userLabelColors[message.user_id] = labelColorsCollection[message.user_label_id]
                
            }
        })
        
        self.finishReceivingMessage()
    }
    
    func addMessage(id: String, text: String, senderName: String, date: NSDate) {
        let message = JSQMessage(senderId: id, senderDisplayName: senderName, date: date, text: text)
        messages.insert(message, atIndex: 0)
    }
    
    private func openWebViewWithUrl(url: String) {
        let controller = WebViewController()
        controller.strURL = url
        controller.strTitle = url
        controller.onTapLinkWithUrl = {[unowned self] tappedUrl in
            if(tappedUrl.absoluteString == "https://www.tokopedia.com/") {
                self.navigationController!.popViewControllerAnimated(true)
            }
        }
        
        self.navigationController?.pushViewController(controller, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    


}
