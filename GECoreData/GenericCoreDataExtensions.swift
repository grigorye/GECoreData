//
//  GenericCoreDataExtensions.swift
//  GEBase
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEFoundation
import GEBase
import CoreData

enum GenericCoreDataExtensionsError: Error {
	case JsonObjectIsNotDictionary(jsonObject: Any)
	case ElementNotFoundOrInvalidInJson(json: [String: AnyObject], elementName: String)
}

public protocol Managed : NSFetchRequestResult {
	static func entityName() -> String
}

public extension Managed {
	static func fetchRequestForEntity() -> NSFetchRequest<Self> {
		return NSFetchRequest(entityName: self.entityName())
	}
}

public protocol DefaultSortable {
	static func defaultSortDescriptor() -> NSSortDescriptor
}

public protocol Identifiable {
	static func identifierKey() -> String
}

public protocol ManagedIdentifiable: Managed, Identifiable {
}

func objectFetchedWithPredicate<T: Managed> (_ cls: T.Type, predicate: NSPredicate, managedObjectContext: NSManagedObjectContext) -> T? where T: NSManagedObject, T: NSFetchRequestResult {
	let request: NSFetchRequest<T> = {
		let $ = T.fetchRequestForEntity()
		$.predicate = predicate
		$.fetchLimit = 1
		return $
	}()
	let objects = try! managedObjectContext.fetch(request)
	let object = objects.last
	if let object = object {
		•(managedObjectContext.object(with: object.objectID))
		assert(object.managedObjectContext == managedObjectContext)
	}
	return object
}

func insertedObjectUnlessFetchedWithPredicate<T: Managed>(_ cls: T.Type, predicate: NSPredicate, managedObjectContext: NSManagedObjectContext, newObjectInitializationHandler: (T) -> Void) throws -> T where T: NSManagedObject, T: NSFetchRequestResult {
	let entityName = cls.entityName()
	if let existingObject = objectFetchedWithPredicate(cls, predicate: predicate, managedObjectContext: managedObjectContext) {
		return existingObject
	}
	else {
		let newObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: managedObjectContext) as! T
		newObjectInitializationHandler(newObject)
		return newObject
	}
}
public func insertedObjectUnlessFetchedWithID<T: NSManagedObject>(_ cls: T.Type, id: String, managedObjectContext: NSManagedObjectContext) throws -> T where T: ManagedIdentifiable, T: NSFetchRequestResult {
	let identifierKey = cls.identifierKey()
	let predicate = NSPredicate(format: "%K == %@", argumentArray: [identifierKey, id])
	return try insertedObjectUnlessFetchedWithPredicate(cls, predicate: predicate, managedObjectContext: managedObjectContext) { newObject in
		(newObject as NSManagedObject).setValue(id, forKey:identifierKey)
	}
}
public func importItemsFromJson<T: ManagedIdentifiable>(_ json: [String : AnyObject], type: T.Type, elementName: String, managedObjectContext: NSManagedObjectContext, importFromJson: (T, [String: AnyObject]) throws -> Void) throws -> [T] where T: NSManagedObject, T: NSFetchRequestResult {
	var items = [T]()
	guard let itemJsons = json[elementName] as? [[String : AnyObject]] else {
		throw GenericCoreDataExtensionsError.ElementNotFoundOrInvalidInJson(json: json, elementName: elementName)
	}
	for itemJson in itemJsons {
		guard let itemID = itemJson["id"] as? String else {
			throw GenericCoreDataExtensionsError.ElementNotFoundOrInvalidInJson(json: json, elementName: "id")
		}
		let item = try insertedObjectUnlessFetchedWithID(type, id: itemID, managedObjectContext: managedObjectContext)
		try importFromJson(item, itemJson)
		items += [item]
	}
	return items
}
public func importItemsFromJsonData<T: ManagedIdentifiable>(_ data: Data, type: T.Type, elementName: String, managedObjectContext: NSManagedObjectContext, importFromJson: (T, [String: AnyObject]) throws -> Void) throws -> [T] where T: NSManagedObject, T: NSFetchRequestResult {
	let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
	guard let json = jsonObject as? [String : AnyObject] else {
		throw GenericCoreDataExtensionsError.JsonObjectIsNotDictionary(jsonObject: jsonObject)
	}
	let items = try importItemsFromJson(json, type: type, elementName: elementName, managedObjectContext: managedObjectContext, importFromJson: importFromJson)
	return items
}

extension NSManagedObject {
	public func encodeObjectIDWithCoder(_ coder: NSCoder, key: String) {
		coder.encode(objectID.uriRepresentation(), forKey: key)
	}
}
extension NSManagedObjectContext {
	public class func objectWithIDDecodedWithCoder(_ coder: NSCoder, key: String, managedObjectContext: NSManagedObjectContext) -> NSManagedObject? {
		if let objectIDURL = coder.decodeObject(forKey: key) as! URL? {
            if let objectID = managedObjectContext.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: objectIDURL) {
                return managedObjectContext.object(with: objectID)
            }
			else {
				$(objectIDURL)
			}
        }
        else {
			$(key)
		}
		return nil
	}
}

public struct TypedManagedObjectID<T> {
	let objectID: NSManagedObjectID
	public func object(in managedObjectContext: NSManagedObjectContext) -> T {
		return managedObjectContext.object(with: objectID) as! T
	}
}

public func typedObjectID<T: NSManagedObject>(for object: T) -> TypedManagedObjectID<T> {
	return TypedManagedObjectID(objectID: object.objectID)
}
public func typedObjectID<T: NSManagedObject>(for object: T?) -> TypedManagedObjectID<T>? {
	guard let object = object else {
		return nil
	}
	return TypedManagedObjectID(objectID: object.objectID)
}

#if os(iOS)
public func stringFromFetchedResultsChangeType(_ type: NSFetchedResultsChangeType) -> String {
	switch (type) {
	case .insert:
		return "Insert"
	case .delete:
		return "Delete"
	case .update:
		return "Update"
	case .move:
		return "Move"
	}
}
#endif
