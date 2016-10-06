//
//  DKImagePickerController.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 14-10-2.
//  Copyright (c) 2014年 ZhangAo. All rights reserved.
//

import UIKit
import AssetsLibrary

// MARK: - Public DKAsset

/**
 * An `DKAsset` object represents a photo or a video managed by the `DKImagePickerController`.
 */
public class DKAsset: NSObject {
    
    /// Returns a CGImage of the representation that is appropriate for displaying full screen.
    public private(set) lazy var fullScreenImage: UIImage? = {
		if let originalAsset = self.originalAsset {
			return UIImage(CGImage: (originalAsset.defaultRepresentation().fullScreenImage().takeUnretainedValue()))
		}
		return nil
    }()
    
    public private(set) lazy var fileName: NSString? = {
        if let originalAsset = self.originalAsset {
            return originalAsset.defaultRepresentation().filename()
        }
        return nil
    }()
    
    /// Returns a CGImage of the representation that is appropriate for displaying full screen.
    public private(set) lazy var resizedImage: UIImage? = {
        if let originalAsset = self.originalAsset {
            let original : UIImage = UIImage(CGImage: (originalAsset.defaultRepresentation().fullResolutionImage().takeUnretainedValue()), scale: 1.0, orientation: UIImageOrientation.Up)
            return self.resizeImage(self.fixOrientation(original))
        }
        return nil
    }()
    
    func resizeImage(original:UIImage)->UIImage {
            var actualHeight = original.size.height
            var actualWidth = original.size.width
            var imgRatio = actualWidth/actualHeight
            let maxImageSize = CGSizeMake(600, 600)
            let widthView = maxImageSize.width;
            let heightView = maxImageSize.height;
            let maxRatio = widthView/heightView;
            
            if (imgRatio != maxRatio){
                if (imgRatio < maxRatio){
                    imgRatio = heightView / actualHeight
                    actualHeight = heightView
                    actualWidth = imgRatio * actualWidth
                } else {
                    imgRatio = widthView / actualWidth
                    actualHeight = imgRatio * actualHeight
                    actualWidth = widthView
                }
            }
            
            let rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
            UIGraphicsBeginImageContext(rect.size)
            original.drawInRect(rect)
            let resized : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            return resized
    }
    
    func fixOrientation(image: UIImage) -> UIImage {
        // No-op if the orientation is already correct
        let orientationInt : Int = Int(self.originalAsset!.valueForProperty("ALAssetPropertyOrientation") as! NSNumber)
        let imageOrientation : UIImageOrientation = UIImageOrientation.init(rawValue: orientationInt)!
        if (imageOrientation == UIImageOrientation.Up) { return image; }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform = CGAffineTransformIdentity
        var newImageWidth : CGFloat = image.size.width
        var newImageHeight : CGFloat = image.size.height
        
        switch (imageOrientation) {
        case .Down, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
            break
        case .Left, .LeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
            newImageWidth = image.size.height
            newImageHeight = image.size.width
            break
        case .Right, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.width)
            transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
            newImageWidth = image.size.height
            newImageHeight = image.size.width
            break
        case .Up, .UpMirrored:
            break
        }
        
        switch (imageOrientation) {
        case .UpMirrored, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
            break
        case .LeftMirrored, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
            break
        case .Up, .Down, .Left, .Right:
            break
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        
        let ctx = CGBitmapContextCreate(nil, Int(newImageWidth), Int(newImageHeight), CGImageGetBitsPerComponent(image.CGImage!), 0, CGImageGetColorSpace(image.CGImage!)!, CGImageGetBitmapInfo(image.CGImage!).rawValue)
        
        CGContextConcatCTM(ctx!, transform);
        
        switch (imageOrientation) {
        case .Left, .LeftMirrored, .Right, .RightMirrored:
            // Grr...
            CGContextDrawImage(ctx!, CGRectMake(0, 0, newImageHeight, newImageWidth), image.CGImage!)
            break
            
        default:
            CGContextDrawImage(ctx!, CGRectMake(0, 0, newImageWidth, newImageHeight), image.CGImage!)
            break
        }
        
        // And now we just create a new UIImage from the drawing context
        let cgimg = CGBitmapContextCreateImage(ctx!)
        let img = UIImage(CGImage: cgimg!)
        
        return img
    }

    
    /// Returns a CGImage representation of the asset.
    public private(set) lazy var fullResolutionImage: UIImage? = {
		if let originalAsset = self.originalAsset {
			return UIImage(CGImage: (originalAsset.defaultRepresentation().fullResolutionImage().takeUnretainedValue()))
		}
		return nil
    }()
    
    /// The url uniquely identifies an asset that is an image or a video.
    public private(set) var url: NSURL?
    
    /// It's a square thumbnail of the asset.
    public private(set) var thumbnailImage: UIImage?
	
	/// The asset's creation date.
	public private(set) lazy var createDate: NSDate? = {
		if let originalAsset = self.originalAsset {
			return originalAsset.valueForProperty(ALAssetPropertyDate) as? NSDate
		}
		return nil
	}()
    
    /// When the asset was an image, it's false. Otherwise true.
    public private(set) var isVideo: Bool = false
    
    /// play time duration(seconds) of a video.
    public private(set) var duration: Double?
    
    internal var isFromCamera: Bool = false
    public private(set) var originalAsset: ALAsset?
	
	/// The source data of the asset.
	public private(set) lazy var rawData: NSData? = {
		if let rep = self.originalAsset?.defaultRepresentation() {
			let sizeOfRawDataInBytes = Int(rep.size())
			let rawData = NSMutableData(length: sizeOfRawDataInBytes)!
			let bufferPtr = rawData.mutableBytes
			let bufferPtr8 = UnsafeMutablePointer<UInt8>(bufferPtr)
			
			rep.getBytes(bufferPtr8, fromOffset: 0, length: sizeOfRawDataInBytes, error: nil)
			return rawData
		}
		return nil
	}()
	
    internal init(originalAsset: ALAsset) {
        super.init()
        
        self.thumbnailImage = UIImage(CGImage:originalAsset.aspectRatioThumbnail().takeUnretainedValue())
        self.url = originalAsset.valueForProperty(ALAssetPropertyAssetURL) as? NSURL
        self.originalAsset = originalAsset
        
        let assetType = originalAsset.valueForProperty(ALAssetPropertyType) as! NSString
        if assetType == ALAssetTypeVideo {
            let duration = originalAsset.valueForProperty(ALAssetPropertyDuration) as! NSNumber
            
            self.isVideo = true
            self.duration = duration.doubleValue
        }
    }
    
    internal init(image: UIImage) {
        super.init()
        
        self.isFromCamera = true
        self.fullScreenImage = image
        self.fullResolutionImage = image
        self.thumbnailImage = image
        self.resizedImage = self.resizeImage(image)
    }
    
    // Compare two DKAssets
    override public func isEqual(object: AnyObject?) -> Bool {
        let another = object as! DKAsset!
        
        if let url = self.url, anotherUrl = another.url {
            return url.isEqual(anotherUrl)
        } else {
            return false
        }
    }
}

/**

 * allPhotos: Get all photos assets in the assets group.
 * allVideos: Get all video assets in the assets group.
 * allAssets: Get all assets in the group.
 */
@objc public enum DKImagePickerControllerAssetType : Int {

    case allPhotos, allVideos, allAssets
}

public struct DKImagePickerControllerSourceType : OptionSetType {
    
    private var value: UInt = 0
    init(_ value: UInt) { self.value = value }
    // MARK: _RawOptionSetType
    public init(rawValue value: UInt) { self.value = value }
    // MARK: NilLiteralConvertible
    public init(nilLiteral: ()) { self.value = 0 }
    // MARK: RawRepresentable
    public var rawValue: UInt { return self.value }
    // MARK: BitwiseOperationsType
    public static var allZeros: DKImagePickerControllerSourceType { return self.init(0) }
    
    public static var Camera: DKImagePickerControllerSourceType { return self.init(1 << 0) }
    public static var Photo: DKImagePickerControllerSourceType { return self.init(1 << 1) }
}

// MARK: - Public DKImagePickerController

/**
 * The `DKImagePickerController` class offers the all public APIs which will affect the UI.
 */
public class DKImagePickerController: UINavigationController {
    
    /// Forces selction of tapped image immediatly
    public var singleSelect = false
    
    /// The maximum count of assets which the user will be able to select.
    public var maxSelectableCount = 999
    
    // The types of ALAssetsGroups to display in the picker
    public var assetGroupTypes: UInt32 = ALAssetsGroupAll

    /// The type of picker interface to be displayed by the controller.
    public var assetType = DKImagePickerControllerAssetType.allAssets
    
    /// If sourceType is Camera will cause the assetType & maxSelectableCount & allowMultipleTypes & defaultSelectedAssets to be ignored.
    public var sourceType: DKImagePickerControllerSourceType = [.Camera, .Photo]
    
    /// Whether allows to select photos and videos at the same time.
    public var allowMultipleTypes = true
	
	/// The callback block is executed when user pressed the cancel button.
	public var didCancel: (() -> Void)?
	public var showCancelButton = false {
		didSet {
			if let rootVC =  self.viewControllers.first {
				if showCancelButton {
//					rootVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
//						target: self,
//						action: "dismiss")
                    let barButtonImage : UIImage = UIImage.init(named: "icon_close_white.png")!
                    rootVC.navigationItem.leftBarButtonItem = UIBarButtonItem(image: barButtonImage,
                        style: .Plain,
                        target: self,
                        action: #selector(DKImagePickerController.dismiss))
				} else {
					rootVC.navigationItem.leftBarButtonItem = nil
				}
			}
		}
	}
	
    /// The callback block is executed when user pressed the select button.
    public var didSelectAssets: ((assets: [DKAsset]) -> Void)?
	
    /// It will have selected the specific assets.
    public var defaultSelectedAssets: [DKAsset]? {
        didSet {
            if let defaultSelectedAssets = self.defaultSelectedAssets {
                for (index, asset) in defaultSelectedAssets.enumerate() {
                    if asset.isFromCamera {
                        self.defaultSelectedAssets!.removeAtIndex(index)
                    }
                }
                
                self.selectedAssets = defaultSelectedAssets
                self.updateDoneButtonTitle()
            }
        }
    }
    
    internal var selectedAssets = [DKAsset]()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: UIButtonType.System)
		button.setTitleColor(UINavigationBar.appearance().tintColor ?? self.navigationBar.tintColor, forState: UIControlState.Normal)
        button.reversesTitleShadowWhenHighlighted = true
        button.addTarget(self, action: #selector(MHVerticalTabBarControllerDelegate.done), forControlEvents: UIControlEvents.TouchUpInside)
      
        return button
    }()
    
    public convenience init() {
        let rootVC = DKAssetGroupDetailVC()
        self.init(rootViewController: rootVC)
      
        rootVC.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.doneButton)
        rootVC.navigationItem.hidesBackButton = true
        rootVC.navigationController?.navigationBar.translucent = false
        self.updateDoneButtonTitle()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DKImagePickerController.selectedImage(_:)),
                                                                   name: DKImageSelectedNotification,
                                                                 object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DKImagePickerController.unselectedImage(_:)),
                                                                   name: DKImageUnselectedNotification,
                                                                 object: nil)
    }
    
    private func updateDoneButtonTitle() {
        if self.selectedAssets.count > 0 {
//            self.doneButton.setTitle(DKImageLocalizedStringWithKey("select") + "(\(selectedAssets.count))", forState: UIControlState.Normal)
            self.doneButton.setTitle(DKImageLocalizedStringWithKey("Selesai"), forState: UIControlState.Normal)
        } else {
            self.doneButton.setTitle(DKImageLocalizedStringWithKey("Selesai"), forState: UIControlState.Normal)
        }
        self.doneButton.sizeToFit()
    }
	
	internal func dismiss() {
		self.dismissViewControllerAnimated(true, completion: nil)
		self.didCancel?()
	}
    internal func done() {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.didSelectAssets?(assets: self.selectedAssets)
    }
    
    // MARK: - Notifications
    
    internal func selectedImage(noti: NSNotification) {
        if let asset = noti.object as? DKAsset {
            selectedAssets.append(asset)
            if asset.isFromCamera {
                self.done()
            } else if self.singleSelect {
                self.done()
            } else {
                updateDoneButtonTitle()
            }
        }
    }
    
    internal func unselectedImage(noti: NSNotification) {
        if let asset = noti.object as? DKAsset {
            selectedAssets.removeAtIndex(selectedAssets.indexOf(asset)!)
            updateDoneButtonTitle()
        }
    }
    
    // MARK: - Handles Orientation

    public override func shouldAutorotate() -> Bool {
        return false
    }
    
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }

}

// MARK: - Utilities

internal extension UIViewController {
    
    var imagePickerController: DKImagePickerController? {
        get {
            let nav = self.navigationController
            if nav is DKImagePickerController {
                return nav as? DKImagePickerController
            } else {
                return nil
            }
        }
    }
    
}
