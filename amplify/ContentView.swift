//
//  ContentView.swift
//  amplify
//
//  Created by Bartłomiej Komarnicki on 12/02/2024.
//

import SwiftUI

struct HeadphoneModel: Identifiable {
    var id = UUID()
    
    var brand: String
    var sku: String
    var impedance: String
    var sensitivity: String
    
    init(raw: [String]) {
        brand = raw[0]
        sku = raw[1]
        impedance = raw[2]
        sensitivity = raw[3]
    }
}

struct Amplifier: Identifiable, Hashable {
    var id = UUID()
    var voltage: String
    var current: String
    var name: String
    
    init(raw: [String]) {
        name = raw[0]
        voltage = raw[1]
        current = raw[2]
    }
}

var headphones = readCSVHeadphones()
var amps = readCSVAmps()


struct ContentView: View {
    @State private var selectedBrand = "Sennheiser"
    @State private var selectedModel = "6XX"
    @State private var loudness = 110
    @State private var showingAddHeadphones = false
    @State private var showingAddAmp = false
    @State private var uniqueBrands = Array(Set(headphones.map { $0.brand })).sorted()
    @State private var ampNames = Array(amps.map { $0.name }.sorted())
    @State private var selectedAmp = amps[0]
    
    var body: some View {
        Form {
            Section("headphones") {
                List {
                    Picker("Brand", selection: $selectedBrand) {
                        ForEach(uniqueBrands, id: \.self) { brand in
                            Text(brand)
                        }
                    }
                    Picker("Model", selection: $selectedModel) {
                        ForEach(headphones.filter( {$0.brand == selectedBrand }).map { $0.sku }.sorted(), id: \.self) { model in
                            Text(model)
                            
                        }
                    }
                }
                Button("Add new headphones") {
                    showingAddHeadphones = true
                }.onChange(of: showingAddHeadphones, initial: true, {
                    uniqueBrands = Array(Set(headphones.map { $0.brand })).sorted()
                })
                .sheet(isPresented: $showingAddHeadphones, content: {
                    AddHeadphones()
                })
            
            }
            let selectedHeadphones = changeBrand(brand: selectedBrand, model: selectedModel)
            let requiredPower = calculatePower(sensitivity: Double(selectedHeadphones.sensitivity) ?? 0, impedance: Double(selectedHeadphones.impedance) ?? 0, loudness: Double(loudness))
            let requiredVoltage = calculateVoltage(power: requiredPower, impedance: Double(selectedHeadphones.impedance) ?? 0)
            let requiredCurrent = calculateCurrent(power: requiredPower, impedance: Double(selectedHeadphones.impedance) ?? 0)
            let ampPower = (Double(selectedAmp.current) ?? 0) * (Double(selectedAmp.current) ?? 0) * (Double(selectedHeadphones.impedance) ?? 0)
            let voltPower = (Double(selectedAmp.voltage) ?? 0) * (Double(selectedAmp.voltage) ?? 0) / (Double (selectedHeadphones.impedance) ?? 0)
            let volume = calculateVolume(sensitivity: Double(selectedHeadphones.sensitivity) ?? 0, impedance: Double(selectedHeadphones.sensitivity) ?? 0, ampPower: ampPower, voltPower: voltPower)
            Section("desired loudness") {
                Stepper("\(loudness) dB", value: $loudness, in: 50...200)
                
            }
            Section("impedance and sensitivity") {
                Text("\(selectedHeadphones.impedance) Ohm, \(selectedHeadphones.sensitivity) dB/mW")
            }
            Section("required power, voltage and current") {
                Text("\(String(format: "%.2f", requiredPower)) mW, \(String(format: "%.2f", requiredVoltage)) V, \(String(format: "%.2f", requiredCurrent)) mA")
            }
            
            
            Section("amplification") {
                Picker("Model", selection: $selectedAmp) {
                    ForEach(amps, id: \.self) { model in
                        Text(model.name)
                    }
                }
                Button("Add new amplifier") {
                    showingAddAmp = true
                }
                .sheet(isPresented: $showingAddAmp, content: {
                    AddAmplifier()
                })
            }
                
            Section("how does it stack up") {
                Text("Your amplifier's voltage is \(selectedAmp.voltage) V RMS, this is " + (Double(selectedAmp.voltage) ?? 0 > requiredVoltage ? "enough." : "not enough."))
                Text("Your amplifier's current is \(selectedAmp.current) mA, this is " + (Double(selectedAmp.current) ?? 0 > requiredCurrent ? "enough." : "not enough."))
                Text("Max volume you could listen to this pair of headphones at with this amplifier is \(Int(volume)) dB" + (volume > 119 ? ", which is way too loud" : "") + ".")
            }
        }
        }
    }

func calculateVolume(sensitivity: Double, impedance: Double, ampPower: Double, voltPower: Double) -> Double {
    let ampSPL = sensitivity + 10 * log10(ampPower / 1000)
    let voltSPL = sensitivity + 10 * log10(voltPower * 1000)
    if ampSPL < voltSPL {
        return ampSPL
    } else {
        print(voltSPL)
        return voltSPL
    }
}
    
func changeBrand(brand: String, model: String) -> HeadphoneModel {
        let filteredModels = headphones.filter { $0.brand == brand }
        let filteredModelsNames = filteredModels.map { $0.sku }.sorted()
        if !filteredModels.filter({ $0.sku == model }).isEmpty {
            return headphones.filter { $0.sku == model }[0]
        } else {
            return filteredModels.filter { $0.sku == filteredModelsNames[0] }[0]
        }
    }

func calculatePower(sensitivity: Double, impedance: Double, loudness: Double) -> Double {
    let weirdStuff = (loudness - sensitivity) / 10
    let power = pow(10, weirdStuff)
    return power
}

func calculateVoltage(power: Double, impedance: Double) -> Double {
    let voltage = sqrt((power / 1000) * impedance)
    print(voltage)
    return voltage
}

func calculateCurrent(power: Double, impedance: Double) -> Double {
    let current = sqrt((power / 1000) / impedance) * 1000
    print(current)
    return current
}

    func readCSVHeadphones() -> [HeadphoneModel] {
        var csvToStruct = [HeadphoneModel]()
        
        guard let filePath = Bundle.main.path(forResource: "cans", ofType: "csv") else {
            return []
        }
        
        var data = ""
        do {
            data = try String(contentsOfFile: filePath)
            
        } catch {
            print(error)
            return []
        }
        
        var rows = data.components(separatedBy: "\n")
        let columnCount = rows.first?.components(separatedBy: ";").count
        rows.removeFirst()
        
        for row in rows {
            let csvColumns = row.components(separatedBy: ";")
            if csvColumns.count == columnCount {
                let headphoneStruct = HeadphoneModel.init(raw: csvColumns)
                csvToStruct.append(headphoneStruct)
            }
        }
        return csvToStruct
    }

func readCSVAmps() -> [Amplifier] {
    var csvToStruct = [Amplifier]()
    
    guard let filePath = Bundle.main.path(forResource: "amps", ofType: "csv") else {
        return []
        }
    
    var data = ""
    do {
        data = try String(contentsOfFile: filePath)
    } catch {
        print(error)
        return []
    }
    
    var rows = data.components(separatedBy: "\n")
    let columnCount = rows.first?.components(separatedBy: ";").count
    rows.removeFirst()
    
    for row in rows {
        let csvColumns = row.components(separatedBy: ";")
        if csvColumns.count == columnCount {
            let ampStruct = Amplifier.init(raw: csvColumns)
            csvToStruct.append(ampStruct)
            
        }
    }
    return csvToStruct
}
#Preview {
    ContentView()
}
