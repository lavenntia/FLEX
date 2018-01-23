//
//  SignInProvider.swift
//  Tokopedia
//
//  Created by Samuel Edwin on 7/13/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit
import RestKit

enum ProviderType {
    case login
    case register
}

class SignInProvider: NSObject {
    var id: String = ""
    var name: String = ""
    var signInUrl: String = ""
    var imageUrl: String = ""
    var color: String = ""

    class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping!.addAttributeMappings(from: [
            "id": "id",
            "name": "name",
            "url": "signInUrl",
            "image": "imageUrl",
            "color": "color"
        ])
        return mapping!
    }

    class func defaultProviders(useFor: ProviderType) -> [SignInProvider] {
        // MARK : List of Provider
        let fbProvider = SignInProvider()
        fbProvider.name = "Facebook"
        fbProvider.id = "facebook"
        fbProvider.imageUrl = "https://ecs1.tokopedia.net/img/icon/facebook_icon.png"
        fbProvider.color = "#3A589B"
        
        let googleProvider = SignInProvider()
        googleProvider.name = "Google"
        googleProvider.id = "gplus"
        googleProvider.imageUrl = "https://ecs1.tokopedia.net/img/icon/gplus_icon.png"
        googleProvider.color = "#FFFFFF"
        
        let yahooProvider = SignInProvider()
        yahooProvider.name = "Yahoo"
        yahooProvider.id = "yahoo"
        yahooProvider.signInUrl = "\(NSString.accountsUrl())/wv/yahoo-login"
        yahooProvider.imageUrl = "https://ecs1.tokopedia.net/img/icon/yahoo_icon.png"
        yahooProvider.color = "#8B2491"
        
        let tokoCashProvider = SignInProvider()
        tokoCashProvider.name = "Nomor Ponsel"
        tokoCashProvider.id = "phoneNumber"
        tokoCashProvider.imageUrl = ""
        tokoCashProvider.color = "#ffffff"
        
        if useFor == .login {
            let loginProvider : [SignInProvider] = [
                fbProvider,
                googleProvider,
                tokoCashProvider,
                yahooProvider
            ]
            return loginProvider
        } else {
            let registerProvider : [SignInProvider] = [
                fbProvider,
                googleProvider
            ]
            return registerProvider
        }
    }
    
    class func touchIdProvider() -> SignInProvider {
        let provider = SignInProvider()
        provider.name = "Touch ID"
        provider.id = "touchid"
        provider.imageUrl = ""
        provider.color = "#ffffff"
        return provider
    }
}
