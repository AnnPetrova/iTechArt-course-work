public class Utils {
	public static list<SelectOption> getPicklistValues(SObject obj, String fld) {
		List<SelectOption> options = new list<SelectOption>();
		Schema.sObjectType objType = obj.getSObjectType();
		Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
		map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

		List<Schema.PicklistEntry> values =
				fieldMap.get(fld).getDescribe().getPickListValues();

		for (Schema.PicklistEntry a : values) {
			options.add(new SelectOption(a.getLabel(), a.getValue()));
		}
		return options;
	}
}