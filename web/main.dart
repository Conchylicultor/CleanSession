import 'dart:async';
import 'package:chrome/chrome_ext.dart' as chrome;


chrome.BookmarkTreeNode cleanFolder = null;
List<chrome.BookmarkTreeNode> savedChildren = null;

void main() async {

  print("Extention launched");

  print("Loading saved tabs");
  
  cleanFolder = (await chrome.bookmarks.search("For Later")).first;
  savedChildren = await chrome.bookmarks.getChildren(cleanFolder.id);
  
  chrome.browserAction.onClicked.listen((e) async {
    print("Click detected");
    
    chrome.Window currentWindow = await chrome.windows.getCurrent(new chrome.WindowsGetCurrentParams(populate:true));
    
    chrome.Tab lastTab = await chrome.tabs.create(new chrome.TabsCreateParams(
        windowId: currentWindow.id, 
        url:      "https://www.google.com/", 
        active:   true));
    
    currentWindow.tabs.forEach((chrome.Tab currentTab) {
      if(currentTab.id != lastTab.id) // We keep one tab open
      {
        if(!currentTab.url.startsWith("chrome://")) // We don't keep standard tabs
        {
          // Save the tab as bookmark
          chrome.CreateDetails newBookmark = new chrome.CreateDetails(
            parentId: cleanFolder.id,
            title:    currentTab.title,
            url:      currentTab.url);
          chrome.bookmarks.create(newBookmark);
        }
        // Close the tab
        chrome.tabs.remove(currentTab.id);
      }
    });
    savedChildren = await chrome.bookmarks.getChildren(cleanFolder.id);

    print('Cleanning finished');
  });
  
  chrome.tabs.onCreated.listen((chrome.Tab newTab) {
    savedChildren.forEach((chrome.BookmarkTreeNode currentNode) {
      if(currentNode.url == newTab.url)
      {
        chrome.bookmarks.remove(currentNode.id).then((e) async {
          savedChildren = await chrome.bookmarks.getChildren(cleanFolder.id);
        });
      }
    });
  });
}
