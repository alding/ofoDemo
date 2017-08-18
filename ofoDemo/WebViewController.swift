//
//  WebViewController.swift
//  ofoDemo
//
//  Created by icecream on 2017/7/31.
//  Copyright © 2017年 何可. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController,WKNavigationDelegate,WKUIDelegate {

    var webView = WKWebView()
    var progressView = UIProgressView()
    var open_url:String = "http://m.ofo.so/active.html"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view.
        webView = WKWebView(frame: self.view.frame)
//        self.title = "热门活动"
        webView.navigationDelegate = self
        webView.uiDelegate = self;
        let url = URL(string: open_url)
        let request = URLRequest(url: url!)
        webView.load(request)
        /**
         增加的属性：
         1.webView.estimatedProgress加载进度
         2.backForwardList 表示historyList
         3.WKWebViewConfiguration *configuration; 初始化webview的配置
         */
        self.view.addSubview(webView)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        progressView = UIProgressView(frame: CGRect(x: 0, y: 44-2, width: UIScreen.main.bounds.size.width, height: 2))
        progressView.trackTintColor = UIColor.white
        progressView.progressTintColor = UIColor.orange
        self.navigationController?.navigationBar.addSubview(progressView)
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "estimatedProgress") {
            progressView.isHidden = webView.estimatedProgress == 1
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
//            print(webView.estimatedProgress)
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.setProgress(0.0, animated: false)
        self.navigationItem.title = webView.title
    }
    
    deinit {
        print("con is deinit")
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        progressView.reloadInputViews()
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
