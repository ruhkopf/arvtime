//
//  TimeEntryImporter.swift
//  arvtime
//
//  Created by patman on 1/10/15.
//  Copyright (c) 2015 arvato Systems. All rights reserved.
//

import Foundation
import Cocoa
import XCGLogger

class TimerEntryImporter {
    let log = XCGLogger.defaultInstance()
    var appPreferenceManager: AppPreferenceManager
    
    init(appPreferenceManager: AppPreferenceManager)
    {
        self.appPreferenceManager = appPreferenceManager
    }
    
    func importTimeEntries(handler: ([TimeEntry]) -> Void) {

        // basic authentication
        let username = appPreferenceManager.appPreferences.togglApiKey
        let password = "api_token"
        let loginString = NSString(format: "%@:%@", username, password)
        let loginData = loginString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64LoginString = loginData?.base64EncodedStringWithOptions(nil)

        var url : String = "https://toggl.com/reports/api/v2/details?workspace_id=229615&since=2015-01-01&until=2015-01-30&user_agent=api_test"
        
        log.info("Starting to import time entries from " + url + " with authorization \(base64LoginString!)")

        // send GET request
        var request : NSMutableURLRequest = NSMutableURLRequest()
        request.URL = NSURL(string: url)
        request.HTTPMethod = "GET"
        request.setValue("Basic \(base64LoginString!)", forHTTPHeaderField: "Authorization")
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler:{ (response:NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            var error: AutoreleasingUnsafeMutablePointer<NSError?> = nil
            let jsonResult: NSDictionary! = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.MutableContainers, error: error) as? NSDictionary
            
            if (jsonResult != nil) {
                // process JSON result
                self.log.debug("\(jsonResult)")
                
                let json = JSON(jsonResult!)
                var entries: [TimeEntry] = []
                
                for (index: String, timeEntryJSON: JSON) in json["data"] {
                    
                    let dateStringFormatter = NSDateFormatter()
                    dateStringFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
                    let date = dateStringFormatter.dateFromString(timeEntryJSON["start"].stringValue)

                    
                    let project = Project(pid: timeEntryJSON["pid"].stringValue, name: timeEntryJSON["project"].stringValue)
                    let task = Task(tid: timeEntryJSON["tid"].stringValue, name: timeEntryJSON["task"].stringValue)
                    let durationInMS = timeEntryJSON["dur"].intValue
                    let durationInHrs = durationInMS / 60 / 60 / 1000
                    
                    let timeEntry = TimeEntry(description: timeEntryJSON["description"].stringValue, duration: durationInHrs, date: NSDate(timeInterval:0, sinceDate:date!), project: project, task: task)
    
                    entries.append(timeEntry)
                }
                
                handler(entries)
                
            } else {
                self.log.error("\(error)")
            }
            
        })
        
    }
    
}
