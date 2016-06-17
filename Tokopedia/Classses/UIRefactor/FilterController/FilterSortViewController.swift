//
//  FilterSortViewController.swift
//  Tokopedia
//
//  Created by Renny Runiawati on 6/7/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit

class FilterSortViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var items : [ListOption] = []
//    private var tempSelectedObject : ListOption = ListOption()
    private weak var selectedObject : ListOption? = ListOption()
    private var completionHandler:(ListOption, [String:String])->Void = {_ in}
    private var completionHandlerResponse:(FilterResponse)->Void = {_ in}
    private var tableView: UITableView = UITableView()
    
    private var refreshControl : UIRefreshControl = UIRefreshControl()
    
    init(items:[ListOption],selectedObject:ListOption, onCompletion: ((ListOption, [String:String]) -> Void), response:((FilterResponse) -> Void)){
        
        completionHandler = onCompletion
        completionHandlerResponse = response
        self.items = items
        self.selectedObject = selectedObject
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        let barButtonBack : UIBarButtonItem = UIBarButtonItem.init(image: UIImage.init(named: "icon_close_white.png"), style: .Plain, target: self, action: #selector(FilterSortViewController.dissmissViewcontroller))
        self.navigationItem.leftBarButtonItem = barButtonBack
        
        let barButtonDone : UIBarButtonItem = UIBarButtonItem.init(title: "Selesai", style: .Plain, target: self, action: #selector(MHVerticalTabBarControllerDelegate.done))
        self.navigationItem.rightBarButtonItem = barButtonDone
        
        tableView = UITableView.init(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height), style: .Plain)
        tableView.dataSource = self
        tableView.delegate = self
        self.tableView.tableFooterView = UIView.init(frame: CGRectMake(0, 0, 1, 1))
        
        self.view.addSubview(self.tableView)
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        refreshControl.addTarget(self, action: Selector("requestFilter"), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        if items.count == 0 {
            tableView.setContentOffset(CGPointMake(0, -refreshControl.frame.size.height), animated:true)
            refreshControl.beginRefreshing()
            
            self .requestFilter()
        }

        self.title = "Urutkan"
    }
    
    func dissmissViewcontroller(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func done(){
        if (selectedObject != nil) {
            completionHandler(selectedObject!, [(selectedObject?.key)!:(selectedObject?.value)!])
        }
        self.dissmissViewcontroller()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        
        let item : ListOption = items[indexPath.row]
        
        let font = UIFont.init(name: "GothamBook", size: 13)
        cell.textLabel?.font = font
        cell.textLabel?.text = item.name
        cell.tintColor = UIColor.init(red: 66/255.0, green: 189/255.0, blue: 65/255.0, alpha: 1)

        cell.selectionStyle = .None
        
        if (selectedObject != nil) {
            if item.value == selectedObject!.value {
                cell.accessoryType = .Checkmark
                tableView .selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Bottom)
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        items[indexPath.row].isSelected = true
        self.selectedObject = items[indexPath.row]
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = .Checkmark
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        items[indexPath.row].isSelected = false

        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = .None
    }

    private func requestFilter(){
        RequestFilter .fetchFilter({ (response) in
            self.items.removeAll()
            
            var indexPaths : [NSIndexPath] = []
            for (index,item) in response.sort.enumerate() {
                self.items.append(item)
                indexPaths.append(NSIndexPath.init(forRow:index , inSection: 0))
            }
            
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            self.tableView.endUpdates()
            
            self.tableView.setContentOffset(CGPointZero, animated:true)
            self.refreshControl.endRefreshing()
            
            self.completionHandlerResponse(response)
            self.tableView.reloadData()
            
        }) { (error) in
            self.tableView.setContentOffset(CGPointZero, animated:true)
            self.refreshControl.endRefreshing()
        }
    }
}
