//
//  ServersViewController.swift
//  DigViewerRemote
//
//  Created by opiopan on 2015/09/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

import UIKit

class ServerInfo : NSObject, NSCoding {
    var service: NSNetService!
    var icon: UIImage!
    var image: UIImage!
    var attributes: [String : String]!
    var isPinned: Bool = false
    var isActive: Bool = false
    
    override init() {
        super.init()
    }
    
    init(src : ServerInfo) {
        super.init()
        service = NSNetService(domain: src.service.domain, type: src.service.type, name: src.service.name)
        icon = src.icon
        image = src.image
        attributes = src.attributes
        isPinned = src.isPinned
        isActive = src.isActive
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        let domain = aDecoder.decodeObjectForKey("domain") as! String
        let type = aDecoder.decodeObjectForKey("type") as! String
        let name = aDecoder.decodeObjectForKey("name") as! String
        service = NSNetService(domain: domain, type: type, name: name)
        icon = aDecoder.decodeObjectForKey("icon") as! UIImage
        image = aDecoder.decodeObjectForKey("image") as! UIImage
        attributes = NSDictionary(coder: aDecoder) as! [String:String]
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(service.domain as NSString, forKey: "domain")
        aCoder.encodeObject(service.type as NSString, forKey: "type")
        aCoder.encodeObject(service.name as NSString, forKey: "name")
        aCoder.encodeObject(icon, forKey: "icon")
        aCoder.encodeObject(image, forKey: "image")
        (attributes as NSDictionary).encodeWithCoder(aCoder)
    }
}

class ServerViewController: UITableViewController, DVRemoteBrowserDelegate, DVRemoteClientDelegate,
                            ConfigurationControllerDelegate {

    private let browser : DVRemoteBrowser = DVRemoteBrowser()

    override func viewDidLoad() {
        super.viewDidLoad()
        browser.delegate = self
        browser.searchServers()

        headerController =
            storyboard!.instantiateViewControllerWithIdentifier("dataSourceHeader") as! DataSourceHeaderController
        footerController =
            storyboard!.instantiateViewControllerWithIdentifier("SimpleFooter") as! SimpleFooterViewController
        let localBrowser = browser
        let localHeader = headerController
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(10 * NSEC_PER_SEC)), dispatch_get_main_queue()){
            if localBrowser.servers.count == 0 {
                localHeader.activityIndicator.stopAnimating()
            }
        }
        
//        syncPinnedList()
        ConfigurationController.sharedController.registerObserver(self)
    }
    
    deinit{
        browser.stop()
        tmpClient.tmpDelegate = nil
        tmpClient.disconnect()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(animated: Bool) {
        syncPinnedList()
    }
    
    override func viewWillDisappear(animated: Bool) {
    }

    @IBAction func closeServersView(sender : UIBarButtonItem?){
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - サーバーリスト操作
    //-----------------------------------------------------------------------------------------
    private var pinnedServers : [ServerInfo] = []
    private var servers : [ServerInfo] = []

    private func syncPinnedList() {
        self.pinnedServers = ConfigurationController.sharedController.dataSourcePinnedList

        // 削除
        let deletee = servers.enumerate().filter{
            [unowned self] in
            let name = $0.element.service.name
            return !$0.element.isActive && self.pinnedServers.filter{$0.service.name == name}.count == 0
        }.reverse().map{NSIndexPath(forRow:$0.index, inSection:0)}
        for index in deletee.reverse() {
            servers.removeAtIndex(index.row)
        }
        tableView.beginUpdates()
        tableView.deleteRowsAtIndexPaths(deletee, withRowAnimation: .Automatic)
        tableView.endUpdates()
        
        // 追加
        let addee = pinnedServers.filter{
            [unowned self] in
            let name = $0.service.name
            return self.servers.filter{$0.service.name == name}.count == 0
        }
        servers.appendContentsOf(addee)
        servers = servers.sort{$0.service.name < $1.service.name}
        let addeeIndexes = pinnedServers.enumerate().filter{
            let name = $0.element.service.name
            return addee.filter{$0.service.name == name}.count > 0
        }.map{NSIndexPath(forRow: $0.index, inSection: 0)}
        tableView.beginUpdates()
        tableView.deleteRowsAtIndexPaths(addeeIndexes, withRowAnimation: .Automatic)
        tableView.endUpdates()
    }
    
    private func registerServer(serverInfo : ServerInfo) {
        let pinnedIndexes = servers.enumerate().filter{$0.element.service.name == serverInfo.service.name}.map{$0.index}
        if let pinnedIndex = pinnedIndexes.first {
            servers[pinnedIndex].isActive = true
            let indexPath = NSIndexPath(forRow: pinnedIndex, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(indexPath){
                setupCell(cell as! DataSourceCell, indexPath: indexPath, animated: true)
            }
        }else{
            serverInfo.isActive = true
            servers.append(serverInfo)
            servers = servers.sort{$0.service.name < $1.service.name}
            let indexes = servers.enumerate().filter{$0.element.service.name == serverInfo.service.name}.map{$0.index}
            if let index = indexes.first {
                tableView.beginUpdates()
                tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
                tableView.endUpdates()
            }
        }
    }
    
    private func unregisterServer(name : String) {
        let indexes = servers.enumerate().filter{$0.element.service.name == name}.map{$0.index}
        if let index = indexes.first {
            let isPinned = servers.filter{$0.service.name == name}.count > 0
            if  isPinned {
                servers[index].isActive = false;
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                    setupCell(cell as! DataSourceCell, indexPath: indexPath, animated: true)
                }
            }else{
                servers.removeAtIndex(index)
                tableView.beginUpdates()
                tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
                tableView.endUpdates()
            }
        }
    }
    
//    func notifyUpdateDataSourceConfiguration(configuration: ConfigurationController) {
//        syncPinnedList()
//    }

    //-----------------------------------------------------------------------------------------
    // MARK: - サーバー探索
    //-----------------------------------------------------------------------------------------
    func dvrBrowserDetectAddServer(browser: DVRemoteBrowser!, service: NSNetService!) {
        let serverInfo = ServerInfo()
        serverInfo.service = service
        addServerInfo(serverInfo)
    }
    
    func dvrBrowserDetectRemoveServer(browser: DVRemoteBrowser!, service: NSNetService!) {
        unregisterServer(service.name)
    }
    
    func dvrBrowser(browser: DVRemoteBrowser!, didNotSearch errorDict: [NSObject : AnyObject]!) {
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - サーバー情報収集
    //-----------------------------------------------------------------------------------------
    private var queryingServers : [ServerInfo] = []
    private let tmpClient = DVRemoteClient.temporaryClient()
    
    private func addServerInfo(serverInfo: ServerInfo){
        queryingServers.append(serverInfo)
        if queryingServers.count == 1 {
            queryServerInfo()
        }
    }
    
    private func queryServerInfo(){
        headerController.activityIndicator.startAnimating()
        tmpClient.tmpDelegate = self
        tmpClient.connectToServer(queryingServers[0].service)
    }
    
    func dvrClient(client: DVRemoteClient!, changeState state: DVRClientState) {
        if state == .Connected {
            client.requestServerInfo()
        }else if state == .Disconnected {
            headerController.activityIndicator.stopAnimating()
            queryingServers.removeAtIndex(0)
            if queryingServers.count > 0 {
                queryServerInfo()
            }
        }
    }
    
    func dvrClient(client: DVRemoteClient!, didRecieveServerInfo info: [NSObject : AnyObject]!) {
        let serverInfo = queryingServers[0];
        serverInfo.attributes = info[DVRCNMETA_SERVER_INFO] as! [String : String]
        serverInfo.icon = UIImage(data: info[DVRCNMETA_SERVER_ICON] as! NSData)
        serverInfo.image = UIImage(data: info[DVRCNMETA_SERVER_IMAGE] as! NSData)
        registerServer(serverInfo)
        client.disconnect()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - セル状態設定
    //-----------------------------------------------------------------------------------------
    private func setupCell(cell : DataSourceCell, indexPath : NSIndexPath, animated : Bool) {
        if animated {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(0.35)
        }

        let serverCount = servers.count;
        let isRemote = indexPath.row < serverCount
        let name = isRemote ? servers[indexPath.row].service.name : AppDelegate.deviceName()
        let icon = isRemote ? servers[indexPath.row].icon : AppDelegate.deviceIcon()
        let description = isRemote ? servers[indexPath.row].attributes[DVRCNMETA_MACHINE_NAME] : nil
        cell.selectionStyle = .Default
        cell.dataSourceLabel.text = name
        cell.dataSourceLabel.textColor = UIColor.blackColor()
        cell.descriptionLabel.text = description
        cell.descriptionLabel.textColor = UIColor(red: 111/256, green: 113/256, blue: 121/256, alpha: 1)
        cell.accessoryType = .None
        cell.iconImageVIew.image = icon
        cell.iconImageVIew.alpha = 1.0
        cell.iconImageVIew.contentMode = .ScaleAspectFit
        
        if isRemote {
            if !servers[indexPath.row].isActive {
                cell.selectionStyle = .None
                cell.dataSourceLabel.textColor = UIColor.lightGrayColor()
                cell.descriptionLabel.textColor = UIColor.lightGrayColor()
                cell.iconImageVIew.alpha = 0.3
            }
            let targetName = servers[indexPath.row].service.name
            cell.detailTransitor = {[unowned self](cell : DataSourceCell) in
                self.detailTargetName = targetName
                self.performSegueWithIdentifier("DataSourceDetail", sender: self)
            }
        }else{
            cell.detailButton.enabled = false
            cell.detailButton.hidden = true
        }
        
        let client = DVRemoteClient.sharedClient()
        if client.state != .Disconnected && client.service == nil && indexPath.row == serverCount {
            cell.accessoryType = .Checkmark
        }else if client.state != .Disconnected && client.service != nil && client.service.name == name {
            cell.accessoryType = .Checkmark
        }

        if animated {
            UIView.commitAnimations()
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - テーブルビュー用データソース
    //-----------------------------------------------------------------------------------------
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servers.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ServerCell", forIndexPath: indexPath) as! DataSourceCell
        setupCell(cell, indexPath: indexPath, animated: false)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let serverCount = servers.count;
        let client = DVRemoteClient.sharedClient()
        if indexPath.row == serverCount {
            var needConnect = false
            if client.state != .Disconnected && client.service != nil {
                client.disconnect()
                needConnect = true
            }else if client.state == .Disconnected {
                needConnect = true
            }
            if needConnect {
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
                dispatch_after(time, dispatch_get_main_queue(), {() -> Void in
                    client.connectToLocal()
                })
            }
        }else{
            if !servers[indexPath.row].isActive {
                return
            }
            let nextServer = servers[indexPath.row].service
            if client.state != .Disconnected && (client.service == nil || client.service!.name != nextServer.name) {
                client.disconnect()
                client.connectToServer(nextServer)
            }else if client.state == .Disconnected {
                client.connectToServer(nextServer)
            }
        }
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private var headerController : DataSourceHeaderController!

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        return 54
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return headerController.view
        }else{
            return super.tableView(tableView, viewForHeaderInSection: section)
        }
    }
    
    private var footerController : SimpleFooterViewController!

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            if footerController.view.subviews.count > 0 {
                footerController.textLabel.text = NSLocalizedString("MSG_DATASOURCE_DESCTIPTION", comment: "")
            }
            return footerController.view
        }else{
            return super.tableView(tableView, viewForFooterInSection: section)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //-----------------------------------------------------------------------------------------
    private var detailTargetName = ""
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DataSourceDetail" {
            let target = segue.destinationViewController as! DataSourceDetailViewController
            let isPinned = pinnedServers.filter{$0.service.name == detailTargetName}.count > 0
            let indexes = servers.enumerate().filter{$0.element.service.name == detailTargetName}.map{$0.index}
            if let index = indexes.first {
                servers[index].isPinned = isPinned
                target.serverInfo = servers[index]
            }
        }
    }

}
