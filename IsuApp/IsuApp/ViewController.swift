//
//  ViewController.swift
//  IsuApp
//
//  Created by 馬聖豪 on 2015/9/30.
//  Copyright © 2015年 adr. All rights reserved.
//

import Cocoa

class ViewController: NSViewController,NSTableViewDelegate, NSTableViewDataSource  {
    
    
    @IBOutlet weak var TvObj: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TvObj.setDelegate(self);
        TvObj.setDataSource(self);
        
        let keychain = Keychain(service: "ISUAPP")
        UserNameTFObj.stringValue = (keychain["username"] == nil ? "" : keychain["username"]!)
        PassWordTFObj.stringValue = (keychain["password"] == nil ? "" : keychain["password"]!)
        if (keychain["password"] != nil) {LoginBtn_Click(self)}
        
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
    func HttpGetSyc(urlstr: String) -> String{
        
        let url = NSURL(string: urlstr)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "GET"
        let big5 = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.Big5_HKSCS_1999.rawValue))
        
        var response: NSURLResponse?
        do {
            let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
            return NSString(data: data, encoding: big5) as! String
        } catch (let e) {
            print(e)
        }
        return ""
    }
    
    func HttpPostSyc(urlstr: String,Param: String, _Refer : String = "") -> String{
        let url = NSURL(string: urlstr)
        let urlrequest = NSMutableURLRequest(URL: url!)
        urlrequest.HTTPMethod = "POST"
        if !_Refer.isEmpty {urlrequest.setValue(_Refer, forHTTPHeaderField: "Referer")}
        
        
        let big5 = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.Big5_HKSCS_1999.rawValue))
        
        urlrequest.HTTPBody = Param.dataUsingEncoding(big5)
        
        
        var response: NSURLResponse?
        do{
            let data = try NSURLConnection.sendSynchronousRequest(urlrequest, returningResponse: &response)
            
            print("error \((response as? NSHTTPURLResponse)?.statusCode)")
            print(response!.URL?.absoluteString)
            return NSString(data: data, encoding: big5) as! String
            
            
        }catch (let e) {
            print(e)
        }
        return ""
    }
    
    
    @IBOutlet weak var UserNameTFObj: NSTextField!
    @IBOutlet weak var PassWordTFObj: NSSecureTextField!
    @IBOutlet weak var StatusLbObj: NSTextField!
    
  
    var objects = ["歡迎使用義守管家OSX版本 v1.0"]
    
    @IBOutlet weak var table_view: NSTableView!
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let content = getData()[row];
        print("\(row): \(content)");
        return content;
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return getData().count;
    }
    
    func getData() -> Array <String> {
        return objects
    }
    
    
    override func viewDidAppear() {
        super.viewDidAppear();
        self.view.window!.title = "isuBot by aaaddress1@gmail.com";
    }
    
    @IBAction func VisitGithub(sender: AnyObject) {
          NSWorkspace.sharedWorkspace().openURL(NSURL(string: "https://github.com/aaaddress1/isuBot-in-Swift")!)
    }

    
    //http://stackoverflow.com/questions/25533147/get-day-of-week-using-nsdate-swift
    func getDayOfWeek()->Int? {
        let todayDate = NSDate()
        let myCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let myComponents = myCalendar?.components(.Weekday, fromDate: todayDate)
        var weekDay = myComponents?.weekday
        weekDay? = weekDay! == 1 ? 7 : weekDay! - 1
        return weekDay
    }
    @IBAction func LogoutBtn_Click(sender: AnyObject) {
        let keychain = Keychain(service: "ISUAPP")
        keychain["username"] = nil
        keychain["password"] = nil
        exit(0)
    }
    @IBAction func LoginBtn_Click(sender: AnyObject) {
        
        let UserName : String = UserNameTFObj.stringValue
        let Password : String = PassWordTFObj.stringValue
        
        HttpPostSyc("http://netreg.isu.edu.tw/wapp/wap_check.asp",Param:"language=zh_TW&lange_sel=zh_TW&logon_id=\(UserName)&txtpasswd=\(Password)&submit1=%B5n%A4J",_Refer: "http://netreg.isu.edu.tw/Wapp/wap_indexmain.asp?call_from=logout")
        
        var Source: String = (HttpGetSyc("http://netreg.isu.edu.tw/Wapp/left.asp"))
        
        do{
            let Reg_Account = try NSRegularExpression(pattern: "登出</font>.{0,100}class=\"myFontClass\">([^<]+)</", options: [.CaseInsensitive])
            let match = Reg_Account.firstMatchInString(Source, options: [], range: NSRange(location: 0, length: (Source.characters.count)))
      
            if (match == nil) {StatusLbObj.stringValue = "Login Fail!" ; return;}
   
            let s2 = (Source as NSString).substringWithRange(match!.rangeAtIndex(1))
            StatusLbObj.stringValue = "Login Succeeed!"
            
            let keychain = Keychain(service: "ISUAPP")
            keychain["username"] = UserName
            keychain["password"] = Password
            UserNameTFObj.enabled = false
            PassWordTFObj.enabled = false
            LoginButtonObj.enabled = false
            
            objects.append("Hello! 您好 \(s2)")
            TvObj.reloadData()
          
            Source = HttpGetSyc("http://netreg.isu.edu.tw/wapp/wap_13/wap_130430.asp")
            Source = Source.stringByReplacingOccurrencesOfString("\n", withString: "")
            Source = Source.stringByReplacingOccurrencesOfString("\r", withString: "")
            Source = Source.stringByReplacingOccurrencesOfString("\t", withString: "")
            Source = Source.stringByReplacingOccurrencesOfString("  ", withString: "")
            objects.append("今日課程")
            
            let Reg_EachData = try NSRegularExpression(pattern:
                "<tdALIGN=\"middle\"style=\"font-size: 10pt\">&nbsp;([^<]+)</td>" +
                "<tdALIGN=\"left\"style=\"font-size: 10pt\">&nbsp;([^<]+)(|<br><font color=[^>]+>[^>]+<br></font>)</td>" +
                "<tdALIGN=\"middle\"style=\"font-size: 10pt\">&nbsp;([^<]+)</td>" +
                "<tdALIGN=\"middle\" style=\"font-size: 10pt\">&nbsp;([^<]+)</td>" +
                "<tdALIGN=\"middle\" style=\"font-size: 10pt\">&nbsp;([^<]+)</td>" +
                "<tdALIGN=\"middle\"style=\"font-size: 10pt\">&nbsp;([^<]+)</td>" +
                "<tdALIGN=\"middle\"style=\"font-size: 10pt\">&nbsp;([^<]+)</td>" +
                "<tdALIGN=\"middle\" style=\"font-size: 10pt\">(<a href=\"[^\"]+\">[^<]+</font></a>|&nbsp; )</td>" +
                "<tdALIGN=\"middle\"style=\"font-size: 10pt\">&nbsp;(.*?)</td>" +
                "<tdALIGN=\"middle\"style=\"font-size: 10pt\">&nbsp;(.*?)</td>" +
                "<tdALIGN=\"middle\"style=\"font-size: 10pt\">&nbsp;(.*?)</td>" +
                "<tdALIGN=\"middle\"style=\"font-size: 10pt\">&nbsp;(.*?)</td>" +
                "<tdALIGN=\"middle\"style=\"font-size: 10pt\">&nbsp;(.*?)</td>" +
                "<tdALIGN=\"middle\"style=\"font-size: 10pt\">&nbsp;(.*?)</td>" +
                "<tdALIGN=\"middle\"style=\"font-size: 10pt\">&nbsp;(.*?)</td>"
            , options: [.CaseInsensitive])
            
            let TodayIndex : Int = getDayOfWeek()!
            let TimeClassXChgList = ["08:20" , "09:20" , "10:20" , "11:20" , "12:20" , "13:30" , "14:30" , "15:30" , "16:30" , "17:30" , "18:50" , "19:40" , "20:30" , "21:20"]
            
            let matchArray = Reg_EachData.matchesInString(Source, options: [], range: NSRange(location:0, length: Source.characters.count))
            for indx in 0..<matchArray.count {
                let mh = matchArray[indx]
                let ClassSource = (Source as NSString)
                
                let CurrDayClassTime : String = ClassSource.substringWithRange(mh.rangeAtIndex(9 + TodayIndex))
                
                for EachChar in CurrDayClassTime.characters
                {
                    let nPos : Int = Int(String(EachChar))!
                    let nTime = TimeClassXChgList[nPos - 1]
                    let nClassName = ClassSource.substringWithRange(mh.rangeAtIndex(2))
                    let nImportTag = ClassSource.substringWithRange(mh.rangeAtIndex(7))
                    let nClassLinkSource = ClassSource.substringWithRange(mh.rangeAtIndex(9))
                    
                    let Reg_ClassLink = try NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</font></a>", options: [.CaseInsensitive])
                    let match = Reg_ClassLink.firstMatchInString(nClassLinkSource, options: [], range: NSRange(location: 0, length: (nClassLinkSource.characters.count)))
                    if match == nil {
                        objects.append(" - \(nImportTag)\t\(nTime)\t\(nClassName)")
                    }else{
                        
                        objects.append(" - \(nImportTag)\t\(nTime)\t\(nClassName)\t教室代號:" + (nClassLinkSource as NSString).substringWithRange(match!.rangeAtIndex(1)))
                    }
                    
                }
            }
             TvObj.reloadData()
            
        }catch (let e)
        {
            print (e)
        }
        
        
        
    }
    @IBOutlet weak var LoginButtonObj: NSButton!
    
    
}

