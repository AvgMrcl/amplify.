//
//  AddHeadphones.swift
//  amplify
//
//  Created by Bartłomiej Komarnicki on 23/02/2024.
//

import SwiftUI
import Foundation


struct AddHeadphones: View {
    @State private var brand = ""
    @State private var model = ""
    @State private var impedance: Int?
    @State private var sensitivity: Int?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                }
                Section {
                    TextField("Impedance", value: $impedance, format: .number)
                    TextField("Sensitivity (dB/mW)", value: $sensitivity, format: .number)
                }.keyboardType(.numberPad)
            }.toolbar {
                Button {
                    if impedance != nil && sensitivity != nil && (!brand.isEmpty) && !model.isEmpty {
                        let data = ("\n\(brand);\(model);\(impedance!);\(sensitivity!);;;")
                        print(data)
                        writeToCSV(data: data)
                        headphones = readCSVHeadphones()
                        dismiss()
                        
                    } else {
                        print("dupa")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            .navigationTitle("New headphones")
        }
    }
}

func writeToCSV(data: String) {
    guard FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first != nil else {
        fatalError("Unable to access documents directory.")
    }
    
    guard let filePath = Bundle.main.path(forResource: "cans", ofType: "csv") else {
        fatalError()
    }

    
//    let fileURL = documentsDirectory.appendingPathComponent("chuj.csv")
    
    if let fileHandle = FileHandle(forWritingAtPath: filePath) {
        // Move to the end of the file
        fileHandle.seekToEndOfFile()
        
        // Convert the data to UTF-8 and write to the file
        if let data = data.data(using: .utf8) {
            fileHandle.write(data)
            
            // Close the file handle
            fileHandle.closeFile()
            
            print("Data successfully appended to \(filePath)")
        } else {
            print("Error converting data to UTF-8.")
        }
    } else {
        print("Error opening the file for writing.")
    }
}
#Preview {
    AddHeadphones()
}
