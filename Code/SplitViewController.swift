/*
View controller managing our split view interface.
*/

import Cocoa

class SplitViewController: NSSplitViewController {

    private var verticalConstraints: [NSLayoutConstraint] = []
    private var horizontalConstraints: [NSLayoutConstraint] = []

    var treeControllerObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        listen(OutlineViewController.Notifications.searchCompleted, react: #selector(handleSearchCompletion(_:)))
        listen(OutlineViewController.Notifications.selectionChanged, react: #selector(handleSelectionChange(_:)))
    }
    
    deinit {
        unlisten(OutlineViewController.Notifications.searchCompleted)
        unlisten(OutlineViewController.Notifications.selectionChanged)
    }

    // MARK: Detail View Controller Management

    private var detailViewController: NSViewController {
        let rightSplitViewItem = splitViewItems[1]
        return rightSplitViewItem.viewController
    }

    private var hasChildViewController: Bool {
        return !detailViewController.children.isEmpty
    }

    private func embedChildViewController(_ childViewController: NSViewController) {
        // To embed a new child view controller.
        let currentDetailVC = detailViewController
        currentDetailVC.addChild(childViewController)
        currentDetailVC.view.addSubview(childViewController.view)

        // Build the horizontal, vertical constraints so that added child view controllers matches the width and height of it's parent.
        let views = ["targetView": childViewController.view]
        horizontalConstraints =
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[targetView]|",
                                           options: [],
                                           metrics: nil,
                                           views: views)
        NSLayoutConstraint.activate(horizontalConstraints)

        verticalConstraints =
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[targetView]|",
                                           options: [],
                                           metrics: nil,
                                           views: views)
        NSLayoutConstraint.activate(verticalConstraints)
    }

    // MARK: Notifications

    // Listens for selection changes to the NSTreeController.
    @objc
    private func handleSelectionChange(_ notification: Notification) {
        // Examine the current selection and adjust the UI.
        let outlineVC = outlineViewController
        guard let treeController = notification.object as? NSTreeController,
                  outlineVC != nil else { return }

        let currentDetailVC = detailViewController

        // Let the outline view controller handle the selection (helps us decide which detail view to use).
        if let vcForDetail = outlineVC!.viewControllerForSelection(treeController.selectedNodes) {
            setChildVC(vcForDetail, currentDetailVC: currentDetailVC)
        } else {
            // No selection, we don't have a child view controller to embed so remove current child view controller.
            if hasChildViewController {
                currentDetailVC.removeChild(at: 0)
                detailViewController.view.subviews[0].removeFromSuperview()
            }
        }
    }
    
    func setChildVC(_ vc: NSViewController, currentDetailVC: NSViewController) {
        if hasChildViewController && currentDetailVC.children[0] != vc {
            /** The incoming child view controller is different from the one we
             currently have, remove the old one and add the new one.
             */
            currentDetailVC.removeChild(at: 0)
            // Remove the old child detail view.
            detailViewController.view.subviews[0].removeFromSuperview()
            // Add the new child detail view.
            embedChildViewController(vc)
        } else {
            if !hasChildViewController {
                // We don't have a child view controller so embed the new one.
                embedChildViewController(vc)
            }
        }
    }
    
    private var outlineViewController: OutlineViewController? {
        return splitViewItems[0].viewController as? OutlineViewController
    }
    
    @objc
    private func handleSearchCompletion(_ notification: Notification) {
        let outlineVC = outlineViewController
        guard outlineVC != nil else { return }
        
        let vcForDetail = outlineVC!.viewControllerForSearch
        setChildVC(vcForDetail, currentDetailVC: detailViewController)
    }
}
