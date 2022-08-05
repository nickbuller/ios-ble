//
//  ContentView.swift
//  BLE Specs:
//  GATTSpecification: https://www.bluetooth.com/specifications/specs/gatt-specification-supplement-6 this contains the structure of data
//
//  Created by Nick Buller on 28/07/2022.
//

import SwiftUI
import CoreBluetooth
import Foundation
import os
import DataDecoder


enum Flavor: String, CaseIterable, Identifiable {
    case chocolate, vanilla, strawberry
    var id: Self { self }
}

class BluetoothManager: NSObject, ObservableObject,
                            CBCentralManagerDelegate,
                            CBPeripheralManagerDelegate,
                            CBPeripheralDelegate
{
   
    var centralManager: CBCentralManager?
    var peripheralManager: CBPeripheralManager?
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BLE")

    @Published var score = 0
    
    @Published var connectedDeviceName: String?
    @Published var availableDeviceNames: [String]
    
    var gattServiceUUID_Glucouse: CBUUID = CBUUID(string: "1808")
        
    var gattCharacteristicsUUID_GlucoseMeasurement: CBUUID = CBUUID(string: "2A18")
    var gattCharacteristicsUUID_GlucoseMeasurementContext: CBUUID = CBUUID(string: "2A34")
    var gattCharacteristicsUUID_GlucoseFeature: CBUUID = CBUUID(string: "2A51")
    var gattCharacteristicsUUID_RecordAccessControlPoint: CBUUID = CBUUID(string: "2A52")
    var gattCharacteristicsUUID_DateTime: CBUUID = CBUUID(string: "2A08")
    
    
    var gattServiceUUID_DeviceInformation: CBUUID = CBUUID(string: "180A")
    
    var gattCharacteristicsUUID_PnPId: CBUUID = CBUUID(string: "2A50")
    var gattCharacteristicsUUID_IEEE11073_20601RegulatoryCertificationDataList: CBUUID = CBUUID(string: "2A2A")
    var gattCharacteristicsUUID_ManufacturerName: CBUUID = CBUUID(string: "2A29")
    var gattCharacteristicsUUID_SystemId: CBUUID = CBUUID(string: "2A23")
    var gattCharacteristicsUUID_ModelNumber: CBUUID = CBUUID(string: "2A24")
    var gattCharacteristicsUUID_SerialNumber: CBUUID = CBUUID(string: "2A25")
    var gattCharacteristicsUUID_FirmwareRevision: CBUUID = CBUUID(string: "2A26")
 
    
    override init() {
        self.availableDeviceNames = [String]()
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
  
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {

        case CBManagerState.poweredOff:
            logger.info("BluetoothManager.CentralManager.State: poweredOff")
        case CBManagerState.poweredOn:
            logger.info("BluetoothManager.CentralManager.State: poweredOn")
            //Start Scanning Here
            self.centralManager?.scanForPeripherals(withServices: [gattServiceUUID_Glucouse], options: nil)
            //self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        case CBManagerState.unsupported:
            logger.info("BluetoothManager.CentralManager.State: unsupported")
        case CBManagerState.resetting:
            logger.info("BluetoothManager.CentralManager.State: resetting")
        case CBManagerState.unauthorized:
            logger.info("BluetoothManager.CentralManager.State: unauthorized")
        case CBManagerState.unknown:
            logger.info("BluetoothManager.CentralManager.State: unknown")
                fallthrough
            default:
                break;
            }
    }
       
    var discoveredPeripheral: CBPeripheral?
        
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        var deviceName: String = String(describing: advertisementData["kCBAdvDataLocalName"])
        var serviceData: Any? = advertisementData["kCBAdvDataServiceData"]
        var dateServiceUUID: String = String(describing: advertisementData["kCBAdvDataServiceUUIDs"])

        if let name = peripheral.name {
            if(!availableDeviceNames.contains(name)) {
                logger.info("CBManager.didDiscover UUID: \(peripheral.identifier.uuidString), Name: \(name)")
                availableDeviceNames.append(name)
            }
            
            advertisementData.forEach { advert in
                logger.info("CBManager.didDiscover.advertisementData[\(name)]: \(advert.key) -> \(String(describing: advert.value))")
            }
            
                //logger.info("Discovering Service for UUID: \(peripheral.identifier.uuidString), Name: \(peripheral.name ?? ""), [\(advertisementData)] RSSI: [\(RSSI)] ")
            logger.info("Discovering Service for UUID: \(peripheral.identifier.uuidString), Name: \(peripheral.name ?? "")")
            discoveredPeripheral = peripheral
            discoveredPeripheral?.delegate = self
            central.connect(peripheral, options: nil)

        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("BluetoothManager.CentralManager.didDisconnectPeripheral: \(peripheral.name ?? peripheral.identifier.uuidString)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("BluetoothManager.CentralManager.didConnect: \(peripheral.name ?? peripheral.identifier.uuidString)")
        central.stopScan()
        centralManager?.registerForConnectionEvents()
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.info("BluetoothManager.CentralManager.didFailToConnect: \(peripheral.name ?? peripheral.identifier.uuidString)")
    }
    
    func peripheralManagerDidUpdateState(_ peripheralManager: CBPeripheralManager) {
        logger.info("BluetoothManager.PeripheralManager: \(peripheralManager.description)")
        
        switch peripheralManager.state {

        case CBManagerState.poweredOff:
            logger.info("BluetoothManager.PeripheralManager.State: poweredOff")
        case CBManagerState.poweredOn:
            logger.info("BluetoothManager.PeripheralManager.State: poweredOn")
        case CBManagerState.unsupported:
            logger.info("BluetoothManager.PeripheralManager.State: unsupported")
        case CBManagerState.resetting:
            logger.info("BluetoothManager.PeripheralManager.State: resetting")
        case CBManagerState.unauthorized:
            logger.info("BluetoothManager.PeripheralManager.State: unauthorized")
        case CBManagerState.unknown:
            logger.info("BluetoothManager.PeripheralManager.State: unknown")
                fallthrough
            default:
                break;
            }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.info("BluetoothManager.Peripheral.didDiscoverServices: \(peripheral.name ?? peripheral.identifier.uuidString)")
        
        peripheral.services?.forEach { service in
            logger.info("BluetoothManager.Peripheral.Service: UUID[0x\(service.uuid.uuidString): \(service.uuid)]")
            peripheral.delegate = self
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
    }
       
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        logger.info("BluetoothManager.Peripheral.didDiscoverCharacteristicsFor: \(service.uuid.uuidString)")
        
        service.characteristics?.forEach { characteristic in
            if(characteristic.properties.contains(.notify) && !characteristic.isNotifying) {
                logger.info("BluetoothManager.Peripheral.Characteristics: Service[0x\(service.uuid.uuidString)] UUID[0x\(characteristic.uuid.uuidString)] Notify, Requesting notifciation")
                peripheral.setNotifyValue(true, for: characteristic)
            } else if(characteristic.properties.contains(.indicate) && !characteristic.isNotifying) {
                logger.info("BluetoothManager.Peripheral.Characteristics: Service[0x\(service.uuid.uuidString)] UUID[0x\(characteristic.uuid.uuidString)] Indicate, Requesting notifciation")
                peripheral.setNotifyValue(true, for: characteristic)

            } else if (characteristic.properties.contains(.read)){
                logger.info("BluetoothManager.Peripheral.Characteristics: Service[0x\(service.uuid.uuidString)] UUID[0x\(characteristic.uuid.uuidString)] Read, Requesting value")
                peripheral.readValue(for: characteristic)
            } else {
                logger.info("BluetoothManager.Peripheral.Characteristics: Service[0x\(service.uuid.uuidString)] UUID[0x\(characteristic.uuid.uuidString)] Other, Ignore")
            }
            
            
            if(service.uuid == gattServiceUUID_Glucouse && characteristic.uuid == gattCharacteristicsUUID_RecordAccessControlPoint) {
                logger.info("BluetoothManager.Peripheral.Characteristics: Service[\(self.gattServiceUUID_Glucouse)] UUID[0x\(self.gattCharacteristicsUUID_RecordAccessControlPoint)] Requesting Report All Stored Records")

                // See GATT Specification for "Record Access Control Point" pg 192
                let reportAll = Data([
                    UInt8(0x01), // OpCode: 0x01 - Report Stored Records
                    UInt8(0x01)  // Operator: 0x01 - All records
                ])
                peripheral.writeValue(reportAll, for: characteristic, type: .withResponse)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let errorVal = error {
            logger.error("BluetoothManager.Peripheral.didUpdateValueFor: Service[0x\(characteristic.service?.uuid.uuidString ?? "")] UUID[0x\(characteristic.uuid.uuidString)] ERROR \(errorVal.localizedDescription.description)")
            return
        } else {
            logServiceAndCharacteristic(service: characteristic.service, characteristic: characteristic)
//            logger.info("BluetoothManager.Peripheral.didUpdateValueFor: Service[0x\(characteristic.service?.uuid.uuidString ?? "")] UUID[0x\(characteristic.uuid.uuidString)] \(self.toString(x: characteristic))")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let errorVal = error {
            logger.error("BluetoothManager.Peripheral.didUpdateNotificationStateFor: Service[0x\(characteristic.service?.uuid.uuidString ?? "")] UUID[0x\(characteristic.uuid.uuidString)] ERROR \(errorVal.localizedDescription.description)")
            return
        } else {
        
        }
    }
    
    func logServiceAndCharacteristic(service: CBService?, characteristic: CBCharacteristic) {
        if let characteristicValue  = characteristic.value {
            let hexData = characteristicValue.map { String(format: "%02hhX", $0) }.joined()
            switch characteristic.service?.uuid {
            case gattServiceUUID_DeviceInformation:

                switch characteristic.uuid {
                case gattCharacteristicsUUID_PnPId:
                    logger.info("Device Information: PnPId - Not interesting")
                case gattCharacteristicsUUID_IEEE11073_20601RegulatoryCertificationDataList:
                    logger.info("Device Information: IEEE11073_20601 - Not interesting")
                case gattCharacteristicsUUID_ManufacturerName:
                    logger.info("Device Information: ManufacturerName: \(String(decoding: characteristicValue, as: UTF8.self))")
                case gattCharacteristicsUUID_SystemId:
                    logger.info("Device Information: SystemId: 0x\(hexData)")
                case gattCharacteristicsUUID_ModelNumber:
                    logger.info("Device Information: ModelNumber: \(String(decoding: characteristicValue, as: UTF8.self))")
                case gattCharacteristicsUUID_SerialNumber:
                    logger.info("Device Information: SerialNumber: \(String(decoding: characteristicValue, as: UTF8.self))")
                case gattCharacteristicsUUID_FirmwareRevision:
                    logger.info("Device Information: FirmwareRevision: \(String(decoding: characteristicValue, as: UTF8.self))")
                default:
                    logger.info("Device Information: Service[0x\(characteristic.service?.uuid.uuidString ?? "")] Unknown Characteristic[0x\(characteristic.uuid.uuidString)] Data[0x\(hexData)]")
                }
                
            case gattServiceUUID_Glucouse:
                switch characteristic.uuid {
                case gattCharacteristicsUUID_GlucoseMeasurement:
                    logger.info("Glucouse: GlucoseMeasurement: \(self.decodeGlucoseMeasurement(data: characteristicValue))")
                case gattCharacteristicsUUID_GlucoseMeasurementContext:
                    logger.info("Glucouse: GlucoseMeasurementContext: \(self.decodeGlucoseMeasurementContext(data: characteristicValue))")
                case gattCharacteristicsUUID_GlucoseFeature:
                    logger.info("Glucouse: GlucoseFeature: \(self.decodeGlucoseFeature(data: characteristicValue))")
                case gattCharacteristicsUUID_RecordAccessControlPoint:
                    logger.info("Glucouse: RecordAccessControlPoint:  \(self.decodeRecordAccessControlPoint(data: characteristicValue))")
                case gattCharacteristicsUUID_DateTime:
                    logger.info("Glucouse: Current Date/Time: \(self.decodeDateTime(data: characteristicValue))")
                default:
                    logger.info("Glucouse: Service[0x\(characteristic.service?.uuid.uuidString ?? "")] Unknown Characteristic[0x\(characteristic.uuid.uuidString)] Data[0x\(hexData)]")
                }
            default:
                logger.info("Unknown: Service[0x\(characteristic.service?.uuid.uuidString ?? "")] Characteristic[0x\(characteristic.uuid.uuidString)] Data[0x\(hexData)]")
            }
        }
    }
    
    func decodeGlucoseMeasurement(data: Data) -> String {
        
        /*
         1     2 3      4-5  6     7   8    9      10     11-12  13-14   15   16     17-18
         Flags Sequence Year Month Day Hour Minute Second OffSet Glucose Type Sample SensorStatus
         0B    0400     E607 07    1E  14   01     08     3900   2CB1    4    A      0000
         1B    0500     E607 07    1E  14   02     03     3900   8FB0    F    8      0000
         0B    0600     E607 07    1E  14   03     06     3900   2CB1    4    A      0000
         0B    0700     E607 07    1E  14   03     34     3900   32B0    4    A      0000
         */
        let timeOffsetFlag: UInt8                                = 0b00000001
        let glucoseConcentrationAndTypeSampleLocationFlag: UInt8 = 0b00000010
        let glucoseUnitsFlag: UInt8                              = 0b00000100
        let sensorStatusAnnunciationFlag: UInt8                  = 0b00001000
        let contextInformationFlag: UInt8                        = 0b00010000
        
        let flags = UInt8((data as NSData)[0])
        let bufferLength = data.count
        let dataAsHex = data.map { String(format: "%02hhX", $0) }.joined()
        
        let sqeuenceNumber = data.subdata(in: 1 ..< 3).withUnsafeBytes {$0.load(as: UInt16.self)}
        let dateTime = decodeDateTime(data: data.subdata(in: 3 ..< 10))
        
        var infoString = "Data[\(dataAsHex)] Len[\(bufferLength)] SequenceNumber[\(sqeuenceNumber)] Date[\(dateTime)] ";
        
        var index = 10
        if((flags & timeOffsetFlag != 0) && (bufferLength > index + 2)) {

            let timeOffSet = data.subdata(in: index ..< index + 2).withUnsafeBytes {$0.load(as: UInt16.self)}
            infoString = infoString + String("TimeOffSet[\(timeOffSet) minutes] ")
            index += 2
        }

        if((flags & glucoseConcentrationAndTypeSampleLocationFlag) != 0 && (bufferLength > index + 3)) {
            let isMmolL = (flags & glucoseUnitsFlag) == 1
            let glucoseConcentration = data.subdata(in: index ..< index + 2).withUnsafeBytes {$0.load(as: Float16.self)}
            let typeSampleLocation = data.subdata(in: index + 2 ..< index + 3).withUnsafeBytes {$0.load(as: UInt8.self)}
            
            var sampleType = ""
            switch typeSampleLocation & 0x0F {
            case 0x01: sampleType = "Capillary Whole blood"
            case 0x02: sampleType = "Capillary Plasma"
            case 0x03: sampleType = "enous Whole blood"
            case 0x04: sampleType = "Venous Plasma"
            case 0x05: sampleType = "Arterial Whole blood"
            case 0x06: sampleType = "Arterial Plasma"
            case 0x07: sampleType = "Undetermined Whole blood"
            case 0x08: sampleType = "Undetermined Plasma"
            case 0x09: sampleType = "Interstitial Fluid (ISF)"
            case 0x0A: sampleType = "Control Solution"
            default: sampleType = "Unknown"
            }
            
            var sampleLocation = ""
            switch (typeSampleLocation & 0xF0) {
            case 0x10: sampleLocation = "Finger"
            case 0x20: sampleLocation = "Alternate Site Test (AST)"
            case 0x30: sampleLocation = "Earlobe"
            case 0x40: sampleLocation = "Control solution"
            case 0xF0: sampleLocation = "Sample Location value not available"
            default: sampleLocation = "Reserved for Future Use"
            }
            
            infoString = infoString + String("GlucoseConcentration[\(glucoseConcentration) \(isMmolL ? "mmol/l" : "mg/dL")] Type[\(sampleType)] Location[\(sampleLocation)] ")
            
            index += 3
        }
               
        if((flags & sensorStatusAnnunciationFlag) != 0 && (bufferLength > index + 1)) {
            let sensorStatus = data.subdata(in: index ..< index + 1).withUnsafeBytes {$0.load(as: UInt8.self)}
            infoString = infoString + String("SensorStatus[\(sensorStatus)] ")
            index += 1
        }
        
        if((flags & contextInformationFlag) != 0 && (bufferLength > index + 2)) {
            let contextInformation = data.subdata(in: index ..< index + 2).withUnsafeBytes {$0.load(as: UInt16.self)}
            infoString = infoString + String("ContextInformation[\(contextInformation)] ")
        }
        return infoString
    }
    
    func decodeGlucoseFeature(data: Data) -> String {
        let lowBattery: UInt16                = 0b0000000000000001
        let sensorMalfunction: UInt16         = 0b0000000000000010
        let sensorSampleSize: UInt16          = 0b0000000000000100
        let sensorStripInsertionError: UInt16 = 0b0000000000001000
        let sensorResultHighLow: UInt16       = 0b0000000000010000
        let sensorTemperatureHighLow: UInt16  = 0b0000000000100000
        let sensorReadInterrupt: UInt16       = 0b0000000001000000
        let generalDeviceFault: UInt16        = 0b0000000010000000
        let timeFault: UInt16                 = 0b0000000100000000
        let multipleBond: UInt16              = 0b0000001000000000
        let reserved: UInt16                  = 0b1111110000000000
        
        var flagDescriptions = [String]()
                
        if(data.count == 2) {
            let flags = data.subdata(in: 0 ..< 2).withUnsafeBytes {$0.load(as: UInt16.self)}
            
            if(flags & lowBattery > 0) { flagDescriptions.append("LowBattery")}
            if(flags & sensorMalfunction > 0) { flagDescriptions.append("SensorMalfunction")}
            if(flags & sensorSampleSize > 0) { flagDescriptions.append("SensorSampleSize")}
            if(flags & sensorStripInsertionError > 0) { flagDescriptions.append("SensorStripInsertionError")}
            if(flags & sensorResultHighLow > 0) { flagDescriptions.append("SensorResultHighLow")}
            if(flags & sensorTemperatureHighLow > 0) { flagDescriptions.append("SensorTemperatureHighLow")}
            if(flags & sensorReadInterrupt > 0) { flagDescriptions.append("SensorReadInterrupt")}
            if(flags & generalDeviceFault > 0) { flagDescriptions.append("GeneralDeviceFault")}
            if(flags & timeFault > 0) { flagDescriptions.append("TimeFault")}
            if(flags & multipleBond > 0) { flagDescriptions.append("MultipleBond")}
            if(flags & reserved > 0) { flagDescriptions.append("ReservedValueUsed[\(flags & reserved >> 10)]")}
        }
        return flagDescriptions.map{String($0)}.joined(separator: ", ")
    }
    
    func decodeGlucoseMeasurementContext(data : Data) -> String {
        let hasCarbohydrates: UInt8   = 0b00000001
        let hasMeal: UInt8            = 0b00000010
        let hasTesterHealth: UInt8    = 0b00000100
        let hasExercise: UInt8        = 0b00001000
        let hasMedication: UInt8      = 0b00010000
        let hasMedicationUnits: UInt8 = 0b00100000 // 0 = milligrams, 1 = milliliters
        let hasHbA1c: UInt8           = 0b01000000
        let hasExtended: UInt8        = 0b10000000
        
        var descriptions = [String]()
        
        if(data.count > 2) {
            let flags = data.subdata(in: 0 ..< 1).withUnsafeBytes {$0.load(as: UInt8.self)}
            let sequence = data.subdata(in: 1 ..< 3).withUnsafeBytes {$0.load(as: UInt16.self)}
            descriptions.append("Sequence[\(sequence)]")
            
            if(flags & hasMeal > 0) {
                let meal = data.subdata(in: 0 ..< 1).withUnsafeBytes {$0.load(as: UInt8.self)}
                if(meal == 0x00) { descriptions.append("Meal[Reserved!]")}
                if(meal == 0x01) { descriptions.append("Meal[Preprandial]")}
                if(meal == 0x02) { descriptions.append("Meal[Postprandial]")}
                if(meal == 0x03) { descriptions.append("Meal[Fasting]")}
                if(meal == 0x04) { descriptions.append("Meal[Casual]")}
                if(meal == 0x05) { descriptions.append("Meal[Bedtime]")}
                if(meal >= 0x06) { descriptions.append("Meal[Reserved]")}
            }
        
        }
        return descriptions.map{String($0)}.joined(separator: ", ")
    }
    
    func decodeRecordAccessControlPoint(data : Data) -> String {
        var descriptions = [String]()
        
        let operationCode = data.subdata(in: 0 ..< 1).withUnsafeBytes {$0.load(as: UInt8.self)}
        let ooperator = data.subdata(in: 1 ..< 2).withUnsafeBytes {$0.load(as: UInt8.self)}
        let operand = data.subdata(in: 2 ..< data.count - 1).map { String(format: "%02hhX", $0) }.joined()
  
        descriptions.append("OpCode: \(operationCode)")
        descriptions.append("Operator: \(ooperator)")
        descriptions.append("Operand: 0x\(operand)")
        
        return descriptions.map{String($0)}.joined(separator: ", ")
    }
       
    func toString( x: CBCharacteristic) -> String {
        return "Properties: [\(toString(x: x.properties))] " +
        "Notifying: [\(x.isNotifying)] " +
        "Descriptor: [\(String(describing: x.descriptors))]"
    }
    
    func toString( x: CBCharacteristicProperties) -> String {
 
        var ret: String = ""
        if(x.contains(CBCharacteristicProperties.authenticatedSignedWrites)) {ret.append("authenticatedSignedWrites,")}
        if(x.contains(CBCharacteristicProperties.broadcast)) {ret.append("broadcast,")}
        if(x.contains(CBCharacteristicProperties.read)) {ret.append("read,")}
        if(x.contains(CBCharacteristicProperties.writeWithoutResponse)) {ret.append("writeWithoutResponse,")}
        if(x.contains(CBCharacteristicProperties.write)) {ret.append("write,")}
        if(x.contains(CBCharacteristicProperties.notify)) {ret.append("notify,")}
        if(x.contains(CBCharacteristicProperties.indicate)) {ret.append("indicate,")}
        if(x.contains(CBCharacteristicProperties.authenticatedSignedWrites)) {ret.append("authenticatedSignedWrites,")}
        if(x.contains(CBCharacteristicProperties.extendedProperties)) {ret.append("extendedProperties,")}
        return ret;
    }
    
    func decodeDateTime(data: Data) -> String {
        if(data.count == 7) {
            let year = data.subdata(in: 0 ..< 2).withUnsafeBytes {$0.load(as: UInt16.self)}
            let month = data.subdata(in: 2 ..< 3).withUnsafeBytes {$0.load(as: UInt8.self)}
            let day = data.subdata(in: 3 ..< 4).withUnsafeBytes {$0.load(as: UInt8.self)}
            let hour = data.subdata(in: 4 ..< 5).withUnsafeBytes {$0.load(as: UInt8.self)}
            let minute = data.subdata(in: 5 ..< 6).withUnsafeBytes {$0.load(as: UInt8.self)}
            let second = data.subdata(in: 6 ..< 7).withUnsafeBytes {$0.load(as: UInt8.self)}
            return String(format: "%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second)
        }
        return "Incorrect buffer length for DateTime"


    }
    
    func toString(x: CBDescriptor) -> String {
        return "\(x)";
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        logger.error("didUpdateValueFor(CBDescriptor)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        logger.error("didWriteValueFor(CBDescriptor)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.error("didWriteValueFor(CBCharacteristic)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        logger.error("didDiscoverDescriptorsFor(CBCharacteristic)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        logger.error("didModifyServices(CBService)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        logger.error("didOpen(CBPeripheral)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        logger.error("didReadRSSI(NSNumber)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        logger.error("didDiscoverIncludedServicesFor(CBService)")
    }
}

struct InnerView: View {
    @ObservedObject var progress: BluetoothManager

    var body: some View {
        ForEach(progress.availableDeviceNames, id: \.self) {
            Button("\($0)") {}
        }
    }
}

struct ContentView: View {
    @StateObject var progress = BluetoothManager()
    @State private var selectedFlavor: Flavor = .chocolate
    var body: some View {
        VStack {
            InnerView(progress: progress)
            List {
                Picker("Flavor", selection: $selectedFlavor) {
                    Text("Chocolate").tag(Flavor.chocolate)
                    Text("Vanilla").tag(Flavor.vanilla)
                    Text("Strawberry").tag(Flavor.strawberry)
                }
            }
        }
        
//        List {
//
//        }.onAppear(perform: onListAppear)

        Text("Hello, world!")
            .lineLimit(20)
            .padding()
    }
    
    private func onListAppear() {
            }
    
}

//
//        /*
//         0     1-2      3-4  5     6   7    8      9      10-11  12-13   14   15     16-17
//         Flags Sequence Year Month Day Hour Minute Second OffSet Glucose Type Sample SensorStatus
//         0B    0400     E607 07    1E  14   01     08     3900   2CB1    4    A      0000
//         1B    0500     E607 07    1E  14   02     03     3900   8FB0    F    8      0000
//         0B    0600     E607 07    1E  14   03     06     3900   2CB1    4    A      0000
//         0B    0700     E607 07    1E  14   03     34     3900   32B0    4    A      0000
//         */
//        /*
//         const measures = Buffer.from(data.value);
//         const year = measures.readUInt16LE(3);
//         const month = ("0" + measures.readUInt8(5)).slice(-2);
//         const day = ("0" + measures.readUInt8(6)).slice(-2);
//         const hours = ("0" + measures.readUInt8(7)).slice(-2);
//         const minutes = ("0" + measures.readUInt8(8)).slice(-2);
//         const seconds = ("0" + measures.readUInt8(9)).slice(-2);
//         const datehms = year + "-" + month + "-" + day + " " + hours + ":" + minutes + ":" + seconds;
//         const date = moment.utc(datehms, 'Y-MM-DD HH:mm:ss').utcOffset(measures.readUInt16LE(10)).format("DD/MM/Y");
//         const time = moment.utc(datehms, 'Y-MM-DD HH:mm:ss').utcOffset(measures.readUInt16LE(10)).format("hh:mm A");
//
//         const flags = Array.from((measures.readUInt8(0) >>> 0).toString(2)).reverse();
//         const unit_flag = flags[3];
//         const glucose_value = measures.readUInt16LE(12);
//         let mantissa = glucose_value & 0x0FFF;
//         let exponent = (glucose_value >> 12);
//
//         if (exponent >= 0x0008) {
//             exponent = -((0x000F + 1) - exponent);
//         }
//
//         if (mantissa >= 0x0800) {
//             mantissa = -((0x0FFF + 1) - mantissa);
//         }
//
//         const magnitude = Math.pow(10, (-1 * exponent));
//
//         let output = mantissa / magnitude;
//         if (unit_flag) {
//             output = output * Math.pow(10, 5);
//         } else {
//             output = output * Math.pow(10, 3);
//             output = output * 18;
//         }
//
//         */
//        var decoder = DecodeData()
//        let data = Data([0x1B,0x05,0x00,0xE6,0x07,0x07,0x1E,0x14,0x02,0x03,0x39,0x00,0x8F,0xB0,0xF8,0x00,0x00])
//
//        let glucose = data.withUnsafeBytes {$0.load(fromByteOffset: 10, as: UInt16.self)}
//        let glucoseSw = data.withUnsafeBytes {$0.load(fromByteOffset: 10, as: UInt16.self)}.byteSwapped
//
//        logger.info("Kiran: \(self.kiran(glucose_value: glucose))")
//        logger.info("KiranSw: \(self.kiran(glucose_value: glucoseSw))")
//        logger.info("extractSFloat: \(self.extractSFloat(full: glucose))")
//        logger.info("extractSFloatSw: \(self.extractSFloat(full: glucoseSw))")
//
//        exit(0)
//    }
//
//    func kiran(glucose_value: UInt16) -> Float {
//
//        let mantissa = (glucose_value & 0x0FFF);
//        let exponent = (glucose_value >> 12);
//
//        var exponentF:Float = 0.0
//        var mantissaF:Float = 0.0
//
//        if (exponent >= 0x0008) {
//            exponentF = -((0x000F + 1) - Float(exponent));
//        }
//
//        if (mantissa >= 0x0800) {
//            mantissaF = -((0x0FFF + 1) - Float(mantissa));
//        }
//
//        let magnitude = pow(10, -1 * exponentF);
//
//        var output = (mantissaF) / (magnitude);
//        let isMmol = false
//        if (isMmol) {
//            output = output * pow(10, 5);
//        } else {
//            output = output * pow(10, 3);
//            output = output * 18;
//        }
//
//        return output;
//    }
//
//
//
//
//    func floatFromTwosComplementUInt16(_ value: UInt16, havingBitsInValueIncludingSign bitsInValueIncludingSign: Int) -> Float {
//        // calculate a signed float from a two's complement signed value
//        // represented in the lowest n ("bitsInValueIncludingSign") bits
//        // of the UInt16 value
//        let signMask: UInt16 = UInt16(0x1) << (bitsInValueIncludingSign - 1)
//        let signMultiplier: Float = (value & signMask == 0) ? 1.0 : -1.0
//
//        var valuePart = value
//        if signMultiplier < 0 {
//            // Undo two's complement if it's negative
//            var valueMask = UInt16(1)
//            for _ in 0 ..< bitsInValueIncludingSign - 2 {
//                valueMask = valueMask << 1
//                valueMask += 1
//            }
//            valuePart = ((~value) & valueMask) &+ 1
//        }
//
//        let floatValue = Float(valuePart) * signMultiplier
//
//        return floatValue
//    }
//
//    func extractSFloat(full: UInt16) -> Float {
//        // IEEE-11073 16-bit SFLOAT -> Float
//
//        // Check special values defined by SFLOAT first
//        if full == 0x07FF {
//            return Float.nan
//        } else if full == 0x800 {
//            return Float.nan // This is really NRes, "Not at this Resolution"
//        } else if full == 0x7FE {
//            return Float.infinity
//        } else if full == 0x0802 {
//            return -Float.infinity // This is really negative infinity
//        } else if full == 0x801 {
//            return Float.nan // This is really RESERVED FOR FUTURE USE
//        }
//
//        // Get exponent (high 4 bits)
//        let expo = (full & 0xF000) >> 12
//        let expoFloat = floatFromTwosComplementUInt16(expo, havingBitsInValueIncludingSign: 4)
//
//        // Get mantissa (low 12 bits)
//        let mantissa = full & 0x0FFF
//        let mantissaFloat = floatFromTwosComplementUInt16(mantissa, havingBitsInValueIncludingSign: 12)
//
//        // Put it together
//        let finalValue = mantissaFloat * pow(10.0, expoFloat)
//
//        return finalValue
//    }
