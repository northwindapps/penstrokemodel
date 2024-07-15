import UIKit
import TensorFlowLite
import PencilKit

class ViewController: BaseController, PKCanvasViewDelegate,PKToolPickerObserver , UIGestureRecognizerDelegate, UITextViewDelegate {
    
    var canvasView: CustomCanvasView!
    var toolPicker: PKToolPicker!
    var interpreter: Interpreter?
    var productsLabel: UILabel!
    
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
        productsLabel.font = UIFont.systemFont(ofSize: 32)
        productsLabel.textColor = .black
        productsLabel.backgroundColor = .clear

        self.view.addSubview(productsLabel)

        // Set up constraints
        NSLayoutConstraint.activate([
            productsLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            productsLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            productsLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20)
        ])
        
        
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
    }
    
}
    
    

    
