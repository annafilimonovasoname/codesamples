public with sharing class CRM_Repository {

	public static Map<String, Map<Integer, sObject>> paramsMap {get; set;}
	public static List<DependencyWrapper> dependencyMatrix {get; set;}

	static {
		paramsMap = new Map<String, Map<Integer, sObject>>();
		dependencyMatrix = new List<DependencyWrapper>();
	}

	public static Integer addItem(String label, sObject	obj) {
		Integer newParentOrder = 0;
        if (paramsMap.get(label) != null) {
        	List<Integer> keySetList = new List<Integer>();
			keySetList.addAll(paramsMap.get(label).keySet());
			for (Integer i = keySetList.size() - 1; i >= 0; i--) {
			   newParentOrder = keySetList.get(i) + 1;
			   break;
			}
        }
        else {
            paramsMap.put(label, new Map<Integer, sObject>());
        }
        paramsMap.get(label).put(newParentOrder, obj);

		return newParentOrder;
	}

	public static Integer addItemWIthDependencies(String parentLabel, Integer parentOrder, String childLabel, sObject childObj, String childFieldName) {
		Integer newChildOrder = addItem(childLabel, childObj);
		addDependency(parentLabel, parentOrder, childLabel, newChildOrder, childFieldName);
		return newChildOrder;
	}

	public static void addDependency(String parentLabel, Integer parentOrder, String childLabel, Integer childOrder, String childFieldName) {
		if (dependencyMatrix == null) {
			dependencyMatrix = new List<DependencyWrapper>();
		}
		DependencyWrapper wrap = new DependencyWrapper();
		wrap.parentLabel = parentLabel;
		wrap.childLabel = childLabel;
		wrap.parentOrder = parentOrder;
		wrap.childOrder = childOrder;
		wrap.childFieldName = childFieldName;
		dependencyMatrix.add(wrap);
	}

	public static void addDependencyList(String parentLabel, Integer parentOrder, String childLabel, List<sObject> childObjects, String childFieldName) {
		if (dependencyMatrix == null) {
			dependencyMatrix = new List<DependencyWrapper>();
		}
		for (sObject childObj : childObjects) {
			Integer childOrder = addItem(childLabel, childObj);
			addDependency(parentLabel, parentOrder, childLabel, childOrder, childFieldName);
		}
	}

	public static Integer addItemsWithDependency(String parentLabel, sObject parentObject, String childLabel, List<sObject> childObjects, String childFieldName) {
		Integer parentOrder = addItem(parentLabel, parentObject);
		for (sObject aChildObject : childObjects) {
			Integer iChildOrder = addItem(childLabel, aChildObject);
			addDependency(parentLabel, parentOrder, childLabel, iChildOrder, childFieldName);
		}
		return parentOrder;
	}

	public static Map<Integer, sObject> getItems(String label) {
		return paramsMap.get(label);
	}

	public static Map<Integer, sObject> getChildItems(String parentLabel, Integer parentOrder, String childLabel) {
		Map<Integer, sObject> returnMap = new Map<Integer, sObject>();
		for (Integer i = 0; i < dependencyMatrix.size(); i++) {
			DependencyWrapper dw = dependencyMatrix.get(i);
			if (dw.parentLabel == parentLabel && dw.parentOrder == parentOrder && dw.childLabel == childLabel) {
				Integer childOrder = dw.childOrder;
				sObject childObj = paramsMap.get(childLabel).get(childOrder);
				if (childObj != null) {
					returnMap.put(childOrder, childObj);
				}
			}
		}
		return returnMap;
	}

	public static void clearRecordsMap() {
		if (paramsMap != null) {
			paramsMap.clear();
		}
	}

	public static void removeItemWithDependencies(String labelToRemove, Integer orderToRemove) {
		paramsMap.get(labelToRemove).remove(orderToRemove);

		Map<String, List<Integer>> recordToRemove = new Map<String, List<Integer>>();
		System.debug('---dependencyMatrix' + dependencyMatrix);
		//List<Integer> wrapIndexesToRemove = new List<Integer>();
		for (Integer i = 0; i < dependencyMatrix.size(); i++) {
			//System.debug('---listElement' + dependencyMatrix.get(i));
			if (dependencyMatrix.get(i).parentLabel == labelToRemove && dependencyMatrix.get(i).parentOrder == orderToRemove) {
				//System.debug('---listElement1' + dependencyMatrix.get(i));
				if (recordToRemove.get(dependencyMatrix.get(i).childLabel) != null) {
	                recordToRemove.get(dependencyMatrix.get(i).childLabel).add(dependencyMatrix.get(i).childOrder);
	            }
	            else {
	                recordToRemove.put(dependencyMatrix.get(i).childLabel, new List<Integer>());
	                recordToRemove.get(dependencyMatrix.get(i).childLabel).add(dependencyMatrix.get(i).childOrder);
	            }

	            //dependencyMatrix.remove(i);
	            //wrapIndexesToRemove.add(i);
			} else if (dependencyMatrix.get(i).childLabel == labelToRemove && dependencyMatrix.get(i).childOrder == orderToRemove) {
				System.debug('----elseCheck' + dependencyMatrix.get(i));
				//wrapIndexesToRemove.add(i);
				dependencyMatrix.remove(i--);
			}
		}
		//for (Integer index : wrapIndexesToRemove) {
		//	dependencyMatrix.remove(index);
		//}
		System.debug('---recordToRemove' + recordToRemove);
		if (!recordToRemove.isEmpty()) {
			for (String label : recordToRemove.keySet()) {
				for (Integer i : recordToRemove.get(label)) {
					removeItemWithDependencies(label, i);
				}
			}
		}
	}

	public static void removeItemWithoutDependencies(String labelToRemove, Integer orderToRemove) {
		paramsMap.get(labelToRemove).remove(orderToRemove);
		for (Integer i = 0; i < dependencyMatrix.size(); i++) {
			if (dependencyMatrix.get(i).parentLabel == labelToRemove && dependencyMatrix.get(i).parentOrder == orderToRemove) {
				dependencyMatrix.remove(i--);
			}
		}
	}

	public static void saveAll() {
		saveWithoutDependencies(paramsMap);
	}

	private static void saveWithoutDependencies(Map<String, Map<Integer, sObject>> objToInsert) {
		Map<String, Map<Integer, sObject>> objToAddLater = new Map<String, Map<Integer, sObject>>();

		for (Integer i = 0; i < dependencyMatrix.size(); i++) {
			DependencyWrapper dw = dependencyMatrix.get(i);
			if (objToInsert.get(dw.childLabel) != null && objToInsert.get(dw.childLabel).get(dw.childOrder) != null) {
				sObject objWithDependency = objToInsert.get(dw.childLabel).get(dw.childOrder);
				objToInsert.get(dw.childLabel).remove(dw.childOrder);

				Map<Integer, sObject> itemToAddLater = objToAddLater.get(dw.childLabel);
				if (itemToAddLater == null) {
					itemToAddLater = new Map<Integer, sObject>();
				}
				itemToAddLater.put(dw.childOrder, objWithDependency);
				objToAddLater.put(dw.childLabel, itemToAddLater);
			}
		}

		List<sObject> lstToCollect = collectObjects(objToInsert);
		System.debug('inserting ' + lstToCollect.size() + 'objects');
		System.debug('inserting: ' + lstToCollect);
		insert lstToCollect;
		//insert collectObjects(objToInsert);
		//Id field should be populated in the objToInsert

		if (dependencyMatrix.isEmpty()) { // last iteration
			return;
		}

		for (Integer i = 0; i < dependencyMatrix.size(); i++) {
			DependencyWrapper dw = dependencyMatrix.get(i);
			if (objToInsert.get(dw.parentLabel) != null && objToInsert.get(dw.parentLabel).get(dw.parentOrder) != null &&
				objToAddLater.get(dw.childLabel) != null && objToAddLater.get(dw.childLabel).get(dw.childOrder) != null) {
				sObject parentObject = objToInsert.get(dw.parentLabel).get(dw.parentOrder);
				sObject childObject = objToAddLater.get(dw.childLabel).get(dw.childOrder);
				childObject.put(dw.childFieldName, parentObject.Id);
				objToAddLater.get(dw.childLabel).put(dw.childOrder, childObject); // do we need to explicitly put?
				dependencyMatrix.remove(i--);
			}
		}

		List<sObject> lstToAddLater = collectObjects(objToAddLater);
		if (lstToAddLater != null && !lstToAddLater.isEmpty()) {
			saveWithoutDependencies(objToAddLater);
		}
	}

	private static List<sObject> collectObjects(Map<String, Map<Integer, sObject>> objToCollect) {
		List<sObject> lstToCollect = new List<sObject>();
		for (String aLabel : objToCollect.keySet()) {
			if (objToCollect.get(aLabel) != null && objToCollect.get(aLabel).values() != null) {
				lstToCollect.addAll(objToCollect.get(aLabel).values());
			}
		}
		return lstToCollect;
	}

	public class DependencyWrapper {
		String parentLabel {get; set;}
		String childLabel {get; set;}
		Integer parentOrder {get; set;}
		Integer childOrder {get; set;}
		String childFieldName {get; set;}
	}

}