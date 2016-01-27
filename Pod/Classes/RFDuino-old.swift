//
//public protocol RFDuinoManagerDelegate {
//  func rfDuinoDidReceiveData(data: NSData?)
//  func managerDidConnectRFDuino(rfDuino: RFduino)
//  func managerDidDisconnectRFDuino(rfDuino: RFduino)
//  func managerDidDiscoverRFDuino(rfDuino: RFduino)
//  func managerdidLoadServiceRFDuino(rfDuino: RFduino)
//}
//
//public class RFDuinoManager : NSObject {
//
//  /* Public variables */
//  public static let sharedInstance = RFDuinoManager()
//  public var delegate: RFDuinoManagerDelegate?
//  
//  /* Private variables */
//  private var discoveredRFDuinos: [RFduino] = []
//  private var connectedRFDuinos: [RFduino] = []
//  private var manager: RFduinoManager?
//  
//  override init() {
//    super.init()
//    manager = RFduinoManager.sharedRFduinoManager()
//    manager!.delegate = self
//  }
//}
//
//extension RFDuinoManager: RFduinoManagerDelegate {
//  
//  @objc
//  public func didDiscoverRFduino(rfDuino: RFduino) {
//    rfDuino.delegate = self
//    discoveredRFDuinos.append(rfDuino)
//    delegate?.managerDidDiscoverRFDuino(rfDuino)
//  }
//  
//  @objc
//  public func didConnectRFduino(rfDuino: RFduino) {
//    connectedRFDuinos.append(rfDuino)
//    delegate?.managerDidConnectRFDuino(rfDuino)
//  }
//  
//  @objc
//  public func didLoadServiceRFduino(rfDuino: RFduino) {
//    delegate?.managerdidLoadServiceRFDuino(rfDuino)
//  }
//  
//  @objc
//  public func didDisconnectRFduino(rfDuino: RFduino) {
//    for (index, otherRfDuino) in connectedRFDuinos.enumerate() {
//      if rfDuino.name == otherRfDuino.name {
//        connectedRFDuinos.removeAtIndex(index)
//      }
//    }
//    delegate?.managerDidDisconnectRFDuino(rfDuino)
//  }
////  @objc
////  public func shouldDisplayAlertTitled(title: NSString?, _ messageBody: NSString?) {
////    
////  }
//}
//
//extension RFDuinoManager: RFduinoDelegate {
//  
//}