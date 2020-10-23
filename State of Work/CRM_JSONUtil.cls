public with sharing class CRM_JSONUtil {

	public static Boolean isObjectExist = false;

	public static void parseJSON(String objName, String jsonStr) {

		List<ParsedObject> parsedList = getParsedObjects(objName, jsonStr, 0, null);

		for (ParsedObject rootObject : parsedList) {
			Integer rootOrder = CRM_Repository.addItem(objName, rootObject.instance);

			for(String childFieldName: rootObject.childObjects.keySet()) {
				List<ParsedObject> childList = rootObject.childObjects.get(childFieldName);
				if (childList.size() > 0) {
					List<sObject> childSobjList = new List<sObject>();
					for (ParsedObject childItem : childList) {
						childSobjList.add(childItem.instance);
					}
					CRM_Repository.addDependencyList(objName, rootOrder, childList[0].objName, childSobjList, childList[0].parentName);					
				}
			}
		}
		System.debug('paramsMap:  ' + CRM_Repository.paramsMap);
		System.debug('dependencyMatrix:  ' + CRM_Repository.dependencyMatrix);
	}

	public static List<ParsedObject> getParsedObjects(String objName, String jsonStr, Integer nestingLevel, JSONParser parser) {
		System.debug('Entering ' + objName);

		if (parser == null) {
			parser = JSON.createParser(jsonStr);
		}

		List<Fields_Mapping__mdt> fieldsMapping = [
			SELECT Input_Json_Field__c, Object_Field__c, Object_Name__c, Json_Object_Label__c, Record_Type__c, Parent_Field_Name__c
			FROM Fields_Mapping__mdt
			WHERE Json_Object_Label__c = :objName
		];

		if (fieldsMapping.isEmpty()) {
			parser.skipChildren();
			return new List<ParsedObject>();
		}

		Map<String, String> fieldsMap = new Map<String, String>();

		for (Fields_Mapping__mdt fieldMapping : fieldsMapping) {
			fieldsMap.put(fieldMapping.Input_Json_Field__c, fieldMapping.Object_Field__c);
		}

	    List<ParsedObject> parsedObjectsList = new List<ParsedObject>();
        System.JSONToken token;
        String fieldName;
        String fieldValue;
        Object currentObj;
        ParsedObject  parsedObj;

        token = parser.nextToken();
        while (token != null) {

            if (token == JSONToken.START_OBJECT) {
            	Schema.SObjectType targetType = Schema.getGlobalDescribe().get(fieldsMapping[0].Object_Name__c);
		        if (targetType != null) {
		        	if (nestingLevel == 0) {
		        		isObjectExist = true;
		        	}
		            sObject sObj = targetType.newSObject();
		            parsedObj = new ParsedObject(objName, sObj);
		        }
            	System.debug('--creating new Object');
   	
            } else if (token == JSONToken.START_ARRAY) {
        		System.debug('--creating new List');
        		System.debug('--nestingLevel: ' + nestingLevel);
        		if (nestingLevel != 0 || isObjectExist) {
        			System.debug('--start new parser: ');
					String currentObjName = fieldName == null ? objName : fieldName;
	        		List<ParsedObject> relatedObjectsList = getParsedObjects(currentObjName, jsonStr, nestingLevel++, parser);
	        		System.debug('--end new parser: ');
	        		nestingLevel--;
	        		if (parsedObj != null) {
            			parsedObj.childObjects.put(currentObjName, relatedObjectsList);
	            	}
            	System.debug('add new List to related: ' + relatedObjectsList);            	
            	} else  {
            		System.debug('--skip new parser: ');
            		nestingLevel++;
            	}
        		System.debug('curent List: ' + parsedObjectsList);          

            } else if (token == JSONToken.END_ARRAY) {	
            	System.debug('--end Array');
            	System.debug('--nestingLevel: ' + nestingLevel);
            	return parsedObjectsList;

            } else if (token == JSONToken.END_OBJECT) {	
            	System.debug('--end Object');

            	if (Schema.getGlobalDescribe().get(fieldsMapping[0].Object_Name__c).getDescribe().getRecordTypeInfosByName().size() > 1 && fieldsMapping[0].Record_Type__c != null) {
            		String recordTypeId = Schema.getGlobalDescribe().get(fieldsMapping[0].Object_Name__c).getDescribe().getRecordTypeInfosByName().get(fieldsMapping[0].Record_Type__c).getRecordTypeId();
            		parsedObj.instance.put('RecordTypeId', recordTypeId);
            	}

        		if (fieldsMapping[0].Parent_Field_Name__c != null) {
    				parsedObj.parentName = fieldsMapping[0].Parent_Field_Name__c;
    			} else {
    				parsedObj.parentName = fieldName == null ? objName : fieldName;
    			}
            	parsedObjectsList.add(parsedObj);
            	parsedObj = null;

            } else if (token == JSONToken.FIELD_Name) {
	            fieldName = parser.getText(); 	  
	            System.debug('--name: ' + fieldName);  

            } else {
            	fieldValue = parser.getText(); 
	            System.debug('--value: ' + fieldValue);        
	            String objFieldName = fieldsMap.get(fieldName);
	            if (objFieldName != null) {
	            	Schema.SObjectType targetType = Schema.getGlobalDescribe().get(fieldsMapping[0].Object_Name__c);
					Schema.DescribeSObjectResult describeSobjResult = targetType.getDescribe();
					Schema.DescribeFieldResult describeFieldResult = describeSobjResult.fields.getMap().get(objFieldName).getDescribe();
					System.debug('---Type: ' + describeFieldResult.getType());

					if (describeFieldResult.getType() == Schema.DisplayType.Percent) {
						parsedObj.instance.put(objFieldName, Double.valueOf(fieldValue));
					} else if (describeFieldResult.getType() == Schema.DisplayType.Integer) {
						parsedObj.instance.put(objFieldName, Integer.valueOf(fieldValue));
					} else if (describeFieldResult.getType() == Schema.DisplayType.Double) {
						parsedObj.instance.put(objFieldName, Double.valueOf(fieldValue));
					} else if (describeFieldResult.getType() == Schema.DisplayType.DateTime) {
						parsedObj.instance.put(objFieldName, Datetime.valueOf(fieldValue));
					} else if (describeFieldResult.getType() == Schema.DisplayType.Date) {
						parsedObj.instance.put(objFieldName, CRM_DateTimeConversionUtils.convertStringtoDate(fieldValue));
					} else if (describeFieldResult.getType() == Schema.DisplayType.Currency) {
						parsedObj.instance.put(objFieldName, Decimal.valueOf(fieldValue));
					} else  {
						parsedObj.instance.put(objFieldName, fieldValue);
					}        
	            }
            }
            token = parser.nextToken();
        }  
        return parsedObjectsList;
	} 

	//Json Generator
	public static String generateJSON(String parentName, String jobId) {

		List<Fields_Mapping_Generator__mdt> parentFieldsMapping = [
			SELECT Json_Object_Label__c, Object_Field__c, Label__c, Parent_Label__c 
			FROM Fields_Mapping_Generator__mdt
			WHERE Label__c = :parentName
		];

		Map<String, String> parentFieldsMap = new Map<String, String>();

		for (Fields_Mapping_Generator__mdt parrentFieldMapping : parentFieldsMapping) {
			parentFieldsMap.put(parrentFieldMapping.Object_Field__c, parrentFieldMapping.Json_Object_Label__c);
		}

		List<Fields_Mapping_Generator__mdt> fieldsMapping = [
			SELECT Json_Object_Label__c, Object_Field__c, Label__c, Parent_Label__c 
			FROM Fields_Mapping_Generator__mdt
			WHERE Parent_Label__c = :parentName
		];

		Map<String, Map<String, String>> childsFieldMap = new Map<String, Map<String, String>>();

		for (Fields_Mapping_Generator__mdt fieldData : fieldsMapping) {
			if (childsFieldMap.containsKey(fieldData.Label__c))  {
				childsFieldMap.get(fieldData.Label__c).put(fieldData.Object_Field__c, fieldData.Json_Object_Label__c);
			} else {
				childsFieldMap.put(fieldData.Label__c, new Map<String, String>{fieldData.Object_Field__c => fieldData.Json_Object_Label__c});
			}

		}

		Map<Integer, sObject> parentsMap = CRM_Repository.getItems(parentName);

		JSONGenerator gen = JSON.createGenerator(true);
		
		gen.writeStartObject();
		gen.writeStringField('JobId', jobId);
		gen.writeFieldName(parentName);
  	    gen.writeStartArray();
		for (Integer parentOrder : parentsMap.keySet()) {
			gen.writeStartObject();
				if (parentName == 'Transactions') {
					gen.writeFieldName('Header');
  	    			gen.writeStartObject();
				}
			Map<String, Object> parentFieldsToValue = parentsMap.get(parentOrder).getPopulatedFieldsAsMap();
			for (String fieldName : parentFieldsToValue.keySet()) {
		        String name = parentFieldsMap.get(fieldName);
		        String value = String.valueOf(parentFieldsToValue.get(fieldName));
		        if (name != null) {
					gen.writeStringField(name, value);
		        }
			}

			if (parentName == 'Transactions') {
				gen.writeEndObject();
			}

			for (String childLabel : childsFieldMap.keySet()) {

				if (childLabel == 'LineItems' || childLabel == 'Payments') {
					gen.writeFieldName(childLabel.trim().removeEnd('s'));
				} else {
					gen.writeFieldName(childLabel);
				}
				
  	     		gen.writeStartArray();

				Map<Integer, sObject> childMap = CRM_Repository.getChildItems(parentName, parentOrder, childLabel);

				for (Integer childOrder : childMap.keySet()) {
					gen.writeStartObject();
					Map<String, Object> childFieldsToValue = childMap.get(childOrder).getPopulatedFieldsAsMap();
					for (String fieldName : childFieldsToValue.keySet()) {
				        String name = childsFieldMap.get(childLabel).get(fieldName);
				        String value = String.valueOf(childFieldsToValue.get(fieldName));
						if (name != null) {
							gen.writeStringField(name, value);
				        }
					}
					gen.writeEndObject();
				}
				gen.writeEndArray();
			}
			gen.writeEndObject();
		}
		gen.writeEndArray();
		gen.writeEndObject();

		String resultJsonString = gen.getAsString();
		return resultJsonString;

	}

	public class ParsedObject {
	    public String objName {get; set;}
	    public String parentName {get; set;}
	    public sObject instance {get; set;}
	    public Map<String,List<ParsedObject>> childObjects {get; set;}
	    
	    public ParsedObject(String objName) {
	        this.objName = objName;
	        this.childObjects = new Map<String,List<ParsedObject>>();
	    }

	    public ParsedObject(String objName, sObject instance) {
	        this.objName = objName;
	        this.instance = instance;
	        this.childObjects = new Map<String,List<ParsedObject>>();
	    }
	}  

}