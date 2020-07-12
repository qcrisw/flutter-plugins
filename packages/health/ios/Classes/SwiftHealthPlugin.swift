import Flutter
import UIKit
import HealthKit

public class SwiftHealthPlugin: NSObject, FlutterPlugin {
    
    let healthStore = HKHealthStore()
    var healthDataTypes = [HKSampleType]()
    var heartRateEventTypes = Set<HKSampleType>()
    var allDataTypes = Set<HKSampleType>()
    var dataTypesDict: [String: HKSampleType] = [:]
    var unitDict: [String: HKUnit] = [:]

    // Health Data Type Keys
    let BODY_FAT_PERCENTAGE = "BODY_FAT_PERCENTAGE"
    let HEIGHT = "HEIGHT"
    let WEIGHT = "WEIGHT"
    let BODY_MASS = "BODY_MASS"
    let BODY_MASS_INDEX = "BODY_MASS_INDEX"
    let LEAN_BODY_MASS = "LEAN_BODY_MASS"
    let WAIST_CIRCUMFERENCE = "WAIST_CIRCUMFERENCE"
    let STEPS = "STEPS"
    let BASAL_ENERGY_BURNED = "BASAL_ENERGY_BURNED"
    let ACTIVE_ENERGY_BURNED = "ACTIVE_ENERGY_BURNED"
    let HEART_RATE = "HEART_RATE"
    let BODY_TEMPERATURE = "BODY_TEMPERATURE"
    let BLOOD_PRESSURE_SYSTOLIC = "BLOOD_PRESSURE_SYSTOLIC"
    let BLOOD_PRESSURE_DIASTOLIC = "BLOOD_PRESSURE_DIASTOLIC"
    let RESTING_HEART_RATE = "RESTING_HEART_RATE"
    let WALKING_HEART_RATE = "WALKING_HEART_RATE"
    let BLOOD_OXYGEN = "BLOOD_OXYGEN"
    let BLOOD_GLUCOSE = "BLOOD_GLUCOSE"
    let ELECTRODERMAL_ACTIVITY = "ELECTRODERMAL_ACTIVITY"
    let HIGH_HEART_RATE_EVENT = "HIGH_HEART_RATE_EVENT"
    let LOW_HEART_RATE_EVENT = "LOW_HEART_RATE_EVENT"
    let IRREGULAR_HEART_RATE_EVENT = "IRREGULAR_HEART_RATE_EVENT"
    let HEART_RATE_VARIABILITY_SDNN = "HEART_RATE_VARIABILITY_SDNN"
    let WALKING_HEART_RATE_AVERAGE = "WALKING_HEART_RATE_AVERAGE"
    let OXYGEN_SATURATION = "OXYGEN_SATURATION"
    let RESPIRATORY_RATE = "RESPIRATORY_RATE"
    let VO2_MAX = "VO2_MAX"
    let BASAL_BODY_TEMPERATURE = "BASAL_BODY_TEMPERATURE"
    let BLOOD_ALCOHOL_CONTENT = "BLOOD_ALCOHOL_CONTENT"
    let FORCED_EXPIRATORY_VOLUME1 = "FORCED_EXPIRATORY_VOLUME1"
    let FORCED_VITAL_CAPACITY = "FORCED_VITAL_CAPACITY"
    let INHALER_USAGE = "INHALER_USAGE"
    let INSULIN_DELIVERY = "INSULIN_DELIVERY"
    let NUMBER_OF_TIMES_FALLEN = "NUMBER_OF_TIMES_FALLEN"
    let PEAK_EXPIRATORY_FLOW_RATE = "PEAK_EXPIRATORY_FLOW_RATE"
    let PERIPHERAL_PERFUSION_INDEX = "PERIPHERAL_PERFUSION_INDEX"
    let DIETARY_ENERGY_CONSUMED = "DIETARY_ENERGY_CONSUMED"
    let DIETARY_FAT_TOTAL = "DIETARY_FAT_TOTAL"
    let DIETARY_FAT_SATURATED = "DIETARY_FAT_SATURATED"
    let DIETARY_CHOLESTEROL = "DIETARY_CHOLESTEROL"
    let DIETARY_CARBOHYDRATES = "DIETARY_CARBOHYDRATES"
    let DIETARY_FIBER = "DIETARY_FIBER"
    let DIETARY_SUGAR = "DIETARY_SUGAR"
    let DIETARY_PROTEIN = "DIETARY_PROTEIN"
    let DIETARY_CALCIUM = "DIETARY_CALCIUM"
    let DIETARY_IRON = "DIETARY_IRON"
    let DIETARY_POTASSIUM = "DIETARY_POTASSIUM"
    let DIETARY_SODIUM = "DIETARY_SODIUM"
    let DIETARY_VITAMIN_A = "DIETARY_VITAMIN_A"
    let DIETARY_VITAMIN_B = "DIETARY_VITAMIN_B"
    let DIETARY_VITAMIN_C = "DIETARY_VITAMIN_C"
    let DIETARY_VITAMIN_D = "DIETARY_VITAMIN_D"
    let DISTANCE_WALKING_RUNNING = "DISTANCE_WALKING_RUNNING"
    let DISTANCE_CYCLING = "DISTANCE_CYCLING"
    let PUSH_COUNT = "PUSH_COUNT"
    let DISTANCE_WHEELCHAIR = "DISTANCE_WHEELCHAIR"
    let SWIMMING_STROKE_COUNT = "SWIMMING_STROKE_COUNT"
    let DISTANCE_SWIMMING = "DISTANCE_SWIMMING"
    let DISTANCE_DOWNHILL_SNOW_SPORTS = "DISTANCE_DOWNHILL_SNOW_SPORTS"
    let FLIGHTS_CLIMBED = "FLIGHTS_CLIMBED"
    let NIKE_FUEL = "NIKE_FUEL"
    let APPLE_STAND_TIME = "APPLE_STAND_TIME"
    let APPLE_EXERCISE_TIME = "APPLE_EXERCISE_TIME"
    let UV_EXPOSURE = "UV_EXPOSURE"
    let ENVIRONMENTAL_AUDIO_EXPOSURE = "ENVIRONMENTAL_AUDIO_EXPOSURE"
    let HEADPHONE_AUDIO_EXPOSURE = "HEADPHONE_AUDIO_EXPOSURE"
                       
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_health", binaryMessenger: registrar.messenger())
        let instance = SwiftHealthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Set up all data types
        initializeTypes()
        
        /// Handle checkIfHealthDataAvailable
        if (call.method.elementsEqual("checkIfHealthDataAvailable")){
            checkIfHealthDataAvailable(call: call, result: result)
        }
        /// Handle requestAuthorization
        else if (call.method.elementsEqual("requestAuthorization")){
            requestAuthorization(call: call, result: result)
        }

        /// Handle getData
        else if (call.method.elementsEqual("getData")){
            if #available(iOS 9.0, *) {
                getData(call: call, result: result)
            } else {
                // Fallback on earlier versions
            }
        }
    }

    func checkIfHealthDataAvailable(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(HKHealthStore.isHealthDataAvailable())
    }

    func requestAuthorization(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        let dataTypeKeys = (arguments?["dataTypeKeys"] as? Array) ?? []
        var dataTypesToRequest = Set<HKSampleType>()
        
        for key in dataTypeKeys {
            let keyString = "\(key)"
            dataTypesToRequest.insert(dataTypeLookUp(key: keyString))
        }

        if #available(iOS 11.2, *) {
            healthStore.requestAuthorization(toShare: nil, read: allDataTypes) { (success, error) in
                result(success)
            }
        } 
        else {
            result(false)// Handle the error here.
        }
    }

    @available(iOS 9.0, *)
    func getData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        let dataTypeKey = (arguments?["dataTypeKey"] as? String) ?? "DEFAULT"
        let startDate = (arguments?["startDate"] as? NSNumber) ?? 0
        let endDate = (arguments?["endDate"] as? NSNumber) ?? 0

        // Convert dates from milliseconds to Date()
        let dateFrom = Date(timeIntervalSince1970: startDate.doubleValue / 1000)
        let dateTo = Date(timeIntervalSince1970: endDate.doubleValue / 1000)

        let dataType = dataTypeLookUp(key: dataTypeKey)
        let predicate = HKQuery.predicateForSamples(withStart: dateFrom, end: dateTo, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let query = HKSampleQuery(sampleType: dataType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) {
            x, samplesOrNil, error in

            guard let samples = samplesOrNil as? [HKQuantitySample] else {
                result(FlutterError(code: "FlutterHealth", message: "Results are null", details: error))
                return
            }
            
            let formatter = DateFormatter()
            // initially set the format based on your datepicker date / server String
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            if (samples != nil){
                result(samples.map { sample -> NSDictionary in

//                     self.healthStore.preferredUnits(for: [sample.quantityType], completion: { (preferredUnits, error) -> Void in
//                         if (error == nil) {

//                             if(self.unitDict[dataTypeKey] == nil)
//                             {
//                                 self.unitDict[dataTypeKey] = preferredUnits[sample.quantityType]
//                             }
                            

//                         }
//                     })
                    
                    let unit = self.unitLookUp(key: dataTypeKey)
                    
                    return [
                        "unit": unit.unitString,
                        "source": sample.sourceRevision.source.name,
                        "device": sample.device != nil ? sample.device!.name! : "",
                        "value": sample.quantity.doubleValue(for: unit),
                        "start_date": sample.startDate,
                        "end_date": sample.endDate,
                    ]
                })
            }
            return
        }
        HKHealthStore().execute(query)
    }

    func unitLookUp(key: String) -> HKUnit {
        guard let unit = unitDict[key] else {
            return HKUnit.count()
        }
        return unit
    }

    func dataTypeLookUp(key: String) -> HKSampleType {
        guard let dataType_ = dataTypesDict[key] else {
            return HKSampleType.quantityType(forIdentifier: .bodyMass)!
        }
        return dataType_
    }

    func initializeTypes() {
        unitDict[BODY_FAT_PERCENTAGE] = HKUnit.percent()
        unitDict[HEIGHT] = HKUnit.meter()
        unitDict[BODY_MASS_INDEX] = HKUnit.init(from: "")
        unitDict[WAIST_CIRCUMFERENCE] = HKUnit.meter()
        unitDict[STEPS] = HKUnit.count()
        unitDict[BASAL_ENERGY_BURNED] = HKUnit.kilocalorie()
        unitDict[ACTIVE_ENERGY_BURNED] = HKUnit.kilocalorie()
        unitDict[HEART_RATE] = HKUnit.init(from: "count/min")
        unitDict[BODY_TEMPERATURE] = HKUnit.degreeCelsius()
        unitDict[BLOOD_PRESSURE_SYSTOLIC] = HKUnit.millimeterOfMercury()
        unitDict[BLOOD_PRESSURE_DIASTOLIC] = HKUnit.millimeterOfMercury()
        unitDict[RESTING_HEART_RATE] = HKUnit.init(from: "count/min")
        unitDict[WALKING_HEART_RATE] = HKUnit.init(from: "count/min")
        unitDict[BLOOD_OXYGEN] = HKUnit.percent()
        unitDict[BLOOD_GLUCOSE] = HKUnit.init(from: "mg/dl")
        unitDict[ELECTRODERMAL_ACTIVITY] = HKUnit.siemen()
        unitDict[WEIGHT] = HKUnit.gramUnit(with: .kilo)



        // Set up iOS 11 specific types (ordinary health data types)
        if #available(iOS 11.2, *) { 
            dataTypesDict[BODY_FAT_PERCENTAGE] = HKSampleType.quantityType(forIdentifier: .bodyFatPercentage)!
            dataTypesDict[HEIGHT] = HKSampleType.quantityType(forIdentifier: .height)!
            dataTypesDict[BODY_MASS_INDEX] = HKSampleType.quantityType(forIdentifier: .bodyMassIndex)!
            dataTypesDict[WAIST_CIRCUMFERENCE] = HKSampleType.quantityType(forIdentifier: .waistCircumference)!
            dataTypesDict[STEPS] = HKSampleType.quantityType(forIdentifier: .stepCount)!
            dataTypesDict[BASAL_ENERGY_BURNED] = HKSampleType.quantityType(forIdentifier: .basalEnergyBurned)!
            dataTypesDict[ACTIVE_ENERGY_BURNED] = HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!
            dataTypesDict[HEART_RATE] = HKSampleType.quantityType(forIdentifier: .heartRate)!
            dataTypesDict[BODY_TEMPERATURE] = HKSampleType.quantityType(forIdentifier: .bodyTemperature)!
            dataTypesDict[BLOOD_PRESSURE_SYSTOLIC] = HKSampleType.quantityType(forIdentifier: .bloodPressureSystolic)!
            dataTypesDict[BLOOD_PRESSURE_DIASTOLIC] = HKSampleType.quantityType(forIdentifier: .bloodPressureDiastolic)!
            dataTypesDict[RESTING_HEART_RATE] = HKSampleType.quantityType(forIdentifier: .restingHeartRate)!
            dataTypesDict[WALKING_HEART_RATE] = HKSampleType.quantityType(forIdentifier: .walkingHeartRateAverage)!
            dataTypesDict[BLOOD_OXYGEN] = HKSampleType.quantityType(forIdentifier: .oxygenSaturation)!
            dataTypesDict[BLOOD_GLUCOSE] = HKSampleType.quantityType(forIdentifier: .bloodGlucose)!
            dataTypesDict[ELECTRODERMAL_ACTIVITY] = HKSampleType.quantityType(forIdentifier: .electrodermalActivity)!
            dataTypesDict[WEIGHT] = HKSampleType.quantityType(forIdentifier: .bodyMass)!
            dataTypesDict[DISTANCE_CYCLING] = HKSampleType.quantityType(forIdentifier: .distanceCycling)!
            dataTypesDict[BODY_MASS] = HKSampleType.quantityType(forIdentifier: .bodyMass)!
            dataTypesDict[LEAN_BODY_MASS] = HKSampleType.quantityType(forIdentifier: .leanBodyMass)!
            dataTypesDict[HEART_RATE_VARIABILITY_SDNN] = HKSampleType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
            dataTypesDict[WALKING_HEART_RATE_AVERAGE] = HKSampleType.quantityType(forIdentifier: .walkingHeartRateAverage)!
            dataTypesDict[OXYGEN_SATURATION] = HKSampleType.quantityType(forIdentifier: .oxygenSaturation)!
            dataTypesDict[RESPIRATORY_RATE] = HKSampleType.quantityType(forIdentifier: .respiratoryRate)!
            dataTypesDict[VO2_MAX] = HKSampleType.quantityType(forIdentifier: .vo2Max)!
            dataTypesDict[BASAL_BODY_TEMPERATURE] = HKSampleType.quantityType(forIdentifier: .basalBodyTemperature)!
            dataTypesDict[BLOOD_ALCOHOL_CONTENT] = HKSampleType.quantityType(forIdentifier: .bloodAlcoholContent)!
            dataTypesDict[BLOOD_GLUCOSE] = HKSampleType.quantityType(forIdentifier: .bloodGlucose)!
            dataTypesDict[FORCED_EXPIRATORY_VOLUME1] = HKSampleType.quantityType(forIdentifier: .forcedExpiratoryVolume1)!
            dataTypesDict[FORCED_VITAL_CAPACITY] = HKSampleType.quantityType(forIdentifier: .forcedVitalCapacity)!
            dataTypesDict[INHALER_USAGE] = HKSampleType.quantityType(forIdentifier: .inhalerUsage)!
            dataTypesDict[INSULIN_DELIVERY] = HKSampleType.quantityType(forIdentifier: .insulinDelivery)!
            dataTypesDict[NUMBER_OF_TIMES_FALLEN] = HKSampleType.quantityType(forIdentifier: .numberOfTimesFallen)!
            dataTypesDict[PEAK_EXPIRATORY_FLOW_RATE] = HKSampleType.quantityType(forIdentifier: .peakExpiratoryFlowRate)!
            dataTypesDict[PERIPHERAL_PERFUSION_INDEX] = HKSampleType.quantityType(forIdentifier: .peripheralPerfusionIndex)!
                   
            dataTypesDict[DIETARY_ENERGY_CONSUMED] = HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
            dataTypesDict[DIETARY_FAT_TOTAL] = HKSampleType.quantityType(forIdentifier: .dietaryFatTotal)!
            dataTypesDict[DIETARY_FAT_SATURATED] = HKSampleType.quantityType(forIdentifier: .dietaryFatSaturated)!
            dataTypesDict[DIETARY_CHOLESTEROL] = HKSampleType.quantityType(forIdentifier: .dietaryCholesterol)!
            dataTypesDict[DIETARY_CARBOHYDRATES] = HKSampleType.quantityType(forIdentifier: .dietaryCarbohydrates)!
            dataTypesDict[DIETARY_FIBER] = HKSampleType.quantityType(forIdentifier: .dietaryFiber)!
            dataTypesDict[DIETARY_SUGAR] = HKSampleType.quantityType(forIdentifier: .dietarySugar)!
            dataTypesDict[DIETARY_PROTEIN] = HKSampleType.quantityType(forIdentifier: .dietaryProtein)!
            dataTypesDict[DIETARY_CALCIUM] = HKSampleType.quantityType(forIdentifier: .dietaryCalcium)!
            dataTypesDict[DIETARY_IRON] = HKSampleType.quantityType(forIdentifier: .dietaryIron)!
            dataTypesDict[DIETARY_POTASSIUM] = HKSampleType.quantityType(forIdentifier: .dietaryPotassium)!
            dataTypesDict[DIETARY_SODIUM] = HKSampleType.quantityType(forIdentifier: .dietarySodium)!
            dataTypesDict[DIETARY_VITAMIN_A] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminA)!
            dataTypesDict[DIETARY_VITAMIN_C] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminC)!
            dataTypesDict[DIETARY_VITAMIN_D] = HKSampleType.quantityType(forIdentifier: .dietaryVitaminD)!
                   
            dataTypesDict[DISTANCE_WALKING_RUNNING] = HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!
            dataTypesDict[PUSH_COUNT] = HKSampleType.quantityType(forIdentifier: .pushCount)!
            dataTypesDict[DISTANCE_WHEELCHAIR] = HKSampleType.quantityType(forIdentifier: .distanceWheelchair)!
            dataTypesDict[SWIMMING_STROKE_COUNT] = HKSampleType.quantityType(forIdentifier: .swimmingStrokeCount)!
            dataTypesDict[DISTANCE_SWIMMING] = HKSampleType.quantityType(forIdentifier: .distanceSwimming)!
            dataTypesDict[DISTANCE_DOWNHILL_SNOW_SPORTS] = HKSampleType.quantityType(forIdentifier: .distanceDownhillSnowSports)!
            dataTypesDict[BASAL_ENERGY_BURNED] = HKSampleType.quantityType(forIdentifier: .basalEnergyBurned)!
            dataTypesDict[ACTIVE_ENERGY_BURNED] = HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!
            dataTypesDict[FLIGHTS_CLIMBED] = HKSampleType.quantityType(forIdentifier: .flightsClimbed)!
            dataTypesDict[NIKE_FUEL] = HKSampleType.quantityType(forIdentifier: .nikeFuel)!
            dataTypesDict[APPLE_EXERCISE_TIME] = HKSampleType.quantityType(forIdentifier: .appleExerciseTime)!
            if #available(iOS 13.0, *) {
                dataTypesDict[APPLE_STAND_TIME] = HKSampleType.quantityType(forIdentifier: .appleStandTime)!
            } else {
                // Fallback on earlier versions
            }
            dataTypesDict[UV_EXPOSURE] = HKSampleType.quantityType(forIdentifier: .uvExposure)!
            if #available(iOS 13.0, *) {
                dataTypesDict[ENVIRONMENTAL_AUDIO_EXPOSURE] = HKSampleType.quantityType(forIdentifier: .environmentalAudioExposure)!
                dataTypesDict[HEADPHONE_AUDIO_EXPOSURE] = HKSampleType.quantityType(forIdentifier: .headphoneAudioExposure)!
            }


            healthDataTypes = Array(dataTypesDict.values)
        }
        // Set up heart rate data types specific to the apple watch, requires iOS 12
        if #available(iOS 12.2, *){
            dataTypesDict[HIGH_HEART_RATE_EVENT] = HKSampleType.categoryType(forIdentifier: .highHeartRateEvent)!
            dataTypesDict[LOW_HEART_RATE_EVENT] = HKSampleType.categoryType(forIdentifier: .lowHeartRateEvent)!
            dataTypesDict[IRREGULAR_HEART_RATE_EVENT] = HKSampleType.categoryType(forIdentifier: .irregularHeartRhythmEvent)!

            heartRateEventTypes =  Set([
                HKSampleType.categoryType(forIdentifier: .highHeartRateEvent)!,
                HKSampleType.categoryType(forIdentifier: .lowHeartRateEvent)!,
                HKSampleType.categoryType(forIdentifier: .irregularHeartRhythmEvent)!,
                ])
        }

        // Concatenate heart events and health data types (both may be empty)
        allDataTypes = Set(heartRateEventTypes + healthDataTypes)
    }
    
}
