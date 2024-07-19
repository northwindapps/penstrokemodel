import UIKit
import TensorFlowLite
import PencilKit
import MessageUI

class ViewController: BaseController, PKCanvasViewDelegate,PKToolPickerObserver , UIGestureRecognizerDelegate, UITextViewDelegate, UITabBarDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate {
    
    var canvasView: CustomCanvasView!
    var toolPicker: PKToolPicker!
    var interpreter: Interpreter?
    var productsLabel: UILabel!
    var textField: UITextField!
    var actionButton: UIButton!
    var tabBar: UITabBar!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        // Create PKCanvasView
        canvasView = CustomCanvasView(dataManager: SharedDataManager())
        
        // Set the frame for canvasView
        canvasView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        
        self.view.addSubview(canvasView)
        
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        canvasView.isUserInteractionEnabled = true
        configureCanvas()
        
        toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(self)
        canvasView.becomeFirstResponder()
        
        // Set up the label
        productsLabel = UILabel()
        productsLabel.translatesAutoresizingMaskIntoConstraints = false
        productsLabel.numberOfLines = 0
        productsLabel.textAlignment = .center
        productsLabel.font = UIFont.systemFont(ofSize: 12)
        productsLabel.textColor = .black
        productsLabel.backgroundColor = .clear

        self.view.addSubview(productsLabel)

        // Set up constraints
        NSLayoutConstraint.activate([
            productsLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            productsLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            productsLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20)
        ])
        
        // Create the UITextField
        textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.placeholder = "Enter text here"
        textField.font = UIFont.systemFont(ofSize: 18)
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        self.view.addSubview(textField)
        
        // Set up constraints for textField
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: productsLabel.bottomAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 40) // Adjust the height as needed
        ])
        // Create the UIButton
        actionButton = UIButton(type: .system)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.setTitle("Add", for: .normal)
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        
        self.view.addSubview(actionButton)
        
        // Set up constraints for textField and actionButton
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: productsLabel.bottomAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            textField.heightAnchor.constraint(equalToConstant: 40),
            
            actionButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 10),
            actionButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            actionButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 80)
        ])
        
        // Add target for the button action
        actionButton.addTarget(self, action: #selector(buttonAddToList), for: .touchUpInside)
        
        // Initialize tab bar
        tabBar = UITabBar()
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        let exportIcon = UIImage(systemName: "square.and.arrow.up")
        let tabBarItem1 = UITabBarItem(title: "Export", image: exportIcon, tag: 0)
        tabBar.items = [tabBarItem1]
        tabBar.delegate = self
        
        // Add tab bar to view
        self.view.addSubview(tabBar)

        // Activate constraints
        NSLayoutConstraint.activate([
            // Tab bar constraints
            tabBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: 49) // Default height for UITabBar
        ])
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        // Handle text changes here
        if let text = textField.text {
            // Do something with the text, such as updating a model or UI
            print("Text changed to: \(text)")
            canvasView.annotation = text
        }
    }
    
    
    @objc func buttonAddToList() {
        if textField.text?.count  == 0{
            print("set annotation")
            return
        }
        canvasView.annotation = textField.text ?? ""
        canvasView.addToManager()
        canvasView.drawing = PKDrawing()
    }
    
    @objc func buttonTapped() {
        // Handle button tap action
        print("Button was tapped!")
    }
    
    func configureCanvas() {
        let penTool = PKInkingTool(.pen, color: .black, width: 1) // Adjust width as needed
        canvasView.tool = penTool
        canvasView.minimumZoomScale = 1.0
        canvasView.maximumZoomScale = 1.0
        canvasView.drawingPolicy = .anyInput
        canvasView.addObserver(self, forKeyPath: "tool", options: .new, context: nil)
        
        
    }
    
    func updateProductsLabel() {
        let joinedString = canvasView.products.joined(separator: "")

        var modifiedString = joinedString.replacingOccurrences(of: ".", with: ".\n")
        modifiedString = modifiedString.replacingOccurrences(of: "?", with: "?\n")
        
        productsLabel.text = modifiedString
        
        canvasView.drawing = PKDrawing()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  // Dismiss keyboard
        return true
    }
    
    
    
    // UITabBarDelegate method
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("Selected item: \(item.tag)")
        sendMail()
    }
    
    func createJSON() -> Data?{
        let jsonAry = DataManagerRepository.shared.sumAllData()
        // Print aggregated data
        print("Data Count: \(jsonAry.count)")
        
        
        
        // Convert the dictionary to JSON
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // Optional, for readability
            let jsonData = try encoder.encode(jsonAry)
            
            // Convert JSON data to a string
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                return jsonData
            }
        } catch {
            print("Failed to encode data: \(error)")
        }
        
        return nil
    }
    
    func saveCSV(csvString: String, fileName: String) {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV saved successfully at \(fileURL)")
        } catch {
            print("Failed to save CSV: \(error)")
        }
    }
    
    func sendMail() {
        if MFMailComposeViewController.canSendMail() {
            let today: Date = Date()
            let dateFormatter: DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
            var date = dateFormatter.string(from: today)

            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self

            mail.setSubject("pen-stroke-data")
            
            let jsonData = createJSON()//createCSV()
            
            if jsonData == nil{
                return
            }
            mail.addAttachmentData(jsonData!, mimeType: "text/json", fileName: "pen_stroke_data_" + date + ".json")

            present(mail, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
    
    

    
