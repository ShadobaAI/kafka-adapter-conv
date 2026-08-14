&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Var DataMetadata, IsSubordinateInformationRegister;
	DataMetadata = Parameters.Data.Metadata();
	
	If Not AccessRight("ViewDataHistory", DataMetadata) Then
		Cancel = True;
		Return;
	EndIf;
	Filter.Insert("Data", Parameters.Data);
	
	Items.VersionsComment.ReadOnly = Not AccessRight("EditDataHistoryVersionComment", DataMetadata);
	
	IsSubordinateInformationRegister = Metadata.InformationRegisters.Contains(DataMetadata) 
		And DataMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate;
	
	If IsSubordinateInformationRegister 
		Or Not AccessRight("SwitchToDataHistoryVersion", DataMetadata) Then
		Items.FormSwitchToVersion.Visible =	False;
		Items.VersionsContextMenuSwitchToVersion.Visible = False;
	EndIf;
	
	Title = 
		GetDataPresentation(DataMetadata, Parameters.Data) +  " (" + 
		NStr("ru = 'История изменений'; SYS = 'DataHistory.VersionsTitle'", "ru")
	 	+ ")";
		
	DataHistory.UpdateHistory(Parameters.Data);	
	SelectVersions();
	RefreshEnabledClearFilter();
EndProcedure

&AtServer
Function GetRussian(English)
	If English = "Data" Then
		Return "Данные";
	ElsIf English = "VersionNumber" Then
		Return "НомерВерсии";
	ElsIf English = "VersionNumberBeforeChange" Then
		Return "НомерВерсииДоИзменения";
	ElsIf English = "VersionNumberAfterChange" Then
		Return "НомерВерсииПослеИзменения";		
	EndIf;		
	Return Undefined;
EndFunction

&AtServer
Function GetCurrentName(English)	
	If  IsEnglish() Then
		Return English;
	Else
		Return GetRussian(English);
	EndIf;
EndFunction

&AtServer
Function GetProperty(Source, English, Result)
	Return Source.Property(English, Result)
		Or Source.Property(GetRussian(English), Result); 
EndFunction

&AtServer
Function GetCurrentProperty(Source, English, Result)
	Return Source.Property(GetCurrentName(English), Result); 
EndFunction

&AtServer
Function IsEnglish()
	Return Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.English;
EndFunction


&AtClient
Procedure RefreshList(Command)
	Versions.Clear();
	SelectVersions();
EndProcedure

&AtServer
Procedure SelectVersions()
	Var Columns, Result, Version, VersionDataChangeType, UserName, Node, ActionsOnVersionEnabled,
		DataChangeTypeIndex, NodeIndex, UserNameIndex, UserFullNameIndex;
	Columns = New Array;
	Columns.Add("VersionNumber");
	Columns.Add("Date");
	Columns.Add("UserName");
	Columns.Add("UserFullName");
	Columns.Add("Comment");
	Columns.Add("DataChangeType");
	Columns.Add("Node");
	
	
	DataChangeTypeIndex = Columns.Find("DataChangeType");
	NodeIndex = Columns.Find("Node");
	UserNameIndex = Columns.Find("UserName");
	UserFullNameIndex = Columns.Find("UserFullName");
	Result = DataHistory.SelectVersions(
		Filter, 
		Columns,
		"VersionNumber Desc");
		
	For Each ResultItem In Result Do
		Version = Versions.Add();
		
		For ColumnIndex = 0 To Columns.Count() - 1 Do
			If ColumnIndex = DataChangeTypeIndex Then
				VersionDataChangeType = ResultItem[DataChangeTypeIndex];
				
				If VersionDataChangeType = DataChangeType.Create Then
					Version.DataChangeType = 0;
				ElsIf VersionDataChangeType = DataChangeType.Update Then
					Version.DataChangeType = 1;
				ElsIf VersionDataChangeType = DataChangeType.Delete Then
					Version.DataChangeType = 2;
				EndIf;
				
			ElsIf ColumnIndex = UserFullNameIndex Then
				UserName = ResultItem[UserFullNameIndex];
				
				If IsBlankString(UserName) Then
					UserName = ResultItem[UserNameIndex];
				EndIf;
				Version.UserName = UserName
			ElsIf ColumnIndex = UserNameIndex Then
				Continue;
			ElsIf ColumnIndex = NodeIndex Then
				Node = ResultItem[NodeIndex];
				If Node = Undefined Then
					Version.Node = NStr("ru = 'Это приложение'; SYS = 'NodeThisApplication'", "ru");
				Else
					Version.Node = String(Node.Metadata()) + "(" + String(Node) + ")" ;
				EndIf;
			Else
				Version[Columns[ColumnIndex]] = ResultItem[ColumnIndex];
			EndIf;
		EndDo;
	EndDo;
	ActionsOnVersionEnabled = Result.Count() > 0;
	Items.FormVersionData.Enabled = ActionsOnVersionEnabled;
	Items.FormVersionDifferences.Enabled = ActionsOnVersionEnabled;
	Items.FormVersionDifferencesWithPrevious.Enabled = ActionsOnVersionEnabled;
	Items.FormVersionDifferencesWithLast.Enabled = ActionsOnVersionEnabled;
	Items.FormSwitchToVersion.Enabled = ActionsOnVersionEnabled;
EndProcedure

&AtClient
Procedure ClearFilter()
	Filter = New Structure("Data", Parameters.Data);
	Versions.Clear();
	SelectVersions();
	RefreshEnabledClearFilter();
EndProcedure

&AtClient
Procedure SetFilter()
	OpenForm("sysForm:DataHistoryVersionsFilterDialog", 
		New Structure("Data, Filter", Parameters.Data, Filter),
		,,,,
		New NotifyDescription("SetFilterCallback", ThisForm));
EndProcedure

&AtClient
Procedure SetFilterCallback(ResultFilter, ExtraParameters) Export
	If ResultFilter <> Undefined Then
		Versions.Clear();
		Filter = ResultFilter;
		Filter.Insert(GetCurrentName("Data"), Parameters.Data);
		SelectVersions();
		RefreshEnabledClearFilter();
	EndIf;
EndProcedure

&AtServer
Procedure RefreshEnabledClearFilter()
	Items.FormClearFilter.Enabled = Filter.Count() > 1;
EndProcedure

&AtServer
Function GetFormNameSwitchToVersion()
	Var DataMetadata;
	DataMetadata = Parameters.Data.Metadata();
	If Metadata.InformationRegisters.Contains(DataMetadata) Then
		Return DataMetadata.FullName() + ".RecordForm";
	ElsIf Metadata.Constants.Contains(DataMetadata) Then
		Return DataMetadata.FullName() + ".ConstantsForm";
	Else
		Return DataMetadata.FullName() + ".ObjectForm";
	EndIf;	
EndFunction

&AtServer
Function GetFormNameByMetadata(FormType)
	Return Parameters.Data.Metadata().FullName() + "." + FormType;
EndFunction

&AtServer
Function GetPreviousVersionNumber(VersionNumber)
	Var PreviousVersionNumber, ExcludeDeleted, Result;
	
	ExcludeDeleted = New Array();
	ExcludeDeleted.Add(DataChangeType.Create);
	ExcludeDeleted.Add(DataChangeType.Update);
	Result = DataHistory.SelectVersions(
		New Structure(
			"Data, DataChangeType", 
			Parameters.Data,
			ExcludeDeleted), 
		"VersionNumber", 
		"VersionNumber Asc");
	For Each CheckVersionNumber In Result Do
		If CheckVersionNumber[0] = VersionNumber Then
			Return PreviousVersionNumber;
		EndIf;
		PreviousVersionNumber = CheckVersionNumber[0];
	EndDo;
	Return PreviousVersionNumber;
EndFunction

&AtServer
Function GetLastVersionNumber()
	Var ExcludeDeleted, Result;
	ExcludeDeleted = New Array();
	ExcludeDeleted.Add(DataChangeType.Create);
	ExcludeDeleted.Add(DataChangeType.Update);
	Result = DataHistory.SelectVersions(
		New Structure(
			"Data, DataChangeType", 
			Parameters.Data,
			ExcludeDeleted), 
		"VersionNumber", 
		"VersionNumber Desc",
		1);
			
	For Each CheckVersionNumber In Result Do
		Return CheckVersionNumber[0];
	EndDo;
	Return Undefined;
EndFunction

&AtClient
Procedure VersionData()
	Var VersionNumber, FormParameters;
	If Not CheckSelectedVersion() Then
		Return;
	EndIf;
	VersionNumber = Items.Versions.CurrentData.VersionNumber;
	If VersionNumber = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert(GetCurrentName("Data"), Parameters.Data);
	FormParameters.Insert(GetCurrentName("VersionNumber"), VersionNumber);
	
	OpenForm(GetFormNameByMetadata("DataHistoryVersionDataForm"), FormParameters);
EndProcedure

&AtClient
Procedure VersionsSelection(Item, SelectedRow, Field, StandardProcessing)
	VersionData();
EndProcedure

&AtClient
Procedure VersionDifferences(Command)
	Var VersionBeforeChange, VersionAfterChange, Version, VersionNumberBeforeChange, VersionNumberAfterChange, FormParameters;
	If Items.Versions.CurrentData = Undefined Then
		Return;
	EndIf;
	VersionBeforeChange = Undefined;
	VersionAfterChange = Undefined;
	
	For Each SelectedRow In Items.Versions.SelectedRows Do
		Version = Items.Versions.RowData(SelectedRow);
		If VersionBeforeChange = Undefined Then
			VersionBeforeChange = Version;
		ElsIf VersionBeforeChange.VersionNumber > Version.VersionNumber Then
			VersionBeforeChange = Version;
		EndIf;
		
		If VersionAfterChange = Undefined Then
			VersionAfterChange = Version;
		ElsIf VersionAfterChange.VersionNumber < Version.VersionNumber Then
			VersionAfterChange = Version;
		EndIf;
	EndDo;
	
	If VersionAfterChange.DataChangeType = 2 Then
		ShowNotAllowedActionsOnDeletedVersion();
		Return;
	EndIf;
	
	If VersionBeforeChange.DataChangeType = 2 Then
		ShowNotAllowedActionsOnDeletedVersion();
		Return;
	EndIf;
	VersionNumberAfterChange = VersionAfterChange.VersionNumber;
	VersionNumberBeforeChange = VersionBeforeChange.VersionNumber;
	
	If  VersionNumberBeforeChange = VersionNumberAfterChange Then
		ShowMessageBox(,NStr("ru='Выберите две версии для сравнения';SYS='DataHistory.SelectVersionsTwoVersions'", "ru"));
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert(GetCurrentName("Data"), Parameters.Data);
	FormParameters.Insert(GetCurrentName("VersionNumberAfterChange"), VersionNumberAfterChange);
	FormParameters.Insert(GetCurrentName("VersionNumberBeforeChange"), VersionNumberBeforeChange);
	OpenForm(GetFormNameByMetadata("DataHistoryVersionDifferencesForm"),FormParameters);  
EndProcedure

&AtClient
Procedure VersionDifferencesWithLast(Command)
	Var BeforeVersionNumber, LastVersionNumber, FormParameters; 
	If Not CheckSelectedVersion() Then
		Return;
	EndIf;

	BeforeVersionNumber = Items.Versions.CurrentData.VersionNumber;
	If BeforeVersionNumber = Undefined Then
		Return;
	EndIf;
	
	LastVersionNumber = GetLastVersionNumber();
	If LastVersionNumber = Undefined Then
		Return;
	EndIf;
	If LastVersionNumber = BeforeVersionNumber Then
		ShowMessageBox(,NStr("ru='Версия является текущей';SYS='DataHistory.VersionIsLast'", "ru"));
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert(GetCurrentName("Data"), Parameters.Data);
	FormParameters.Insert(GetCurrentName("VersionNumberAfterChange"), LastVersionNumber);
	FormParameters.Insert(GetCurrentName("VersionNumberBeforeChange"), BeforeVersionNumber);
	
	OpenForm(GetFormNameByMetadata("DataHistoryVersionDifferencesForm"), FormParameters);
EndProcedure

&AtClient
Procedure VersionDifferencesWithPrevious(Command)
	Var AfterVersionNumber, BeforeVersionNumber, FormParameters;
	If Not CheckSelectedVersion() Then
		Return;
	EndIf;
	
	AfterVersionNumber = Items.Versions.CurrentData.VersionNumber;
	If AfterVersionNumber = Undefined Then
		Return;
	EndIf;
	BeforeVersionNumber = GetPreviousVersionNumber(AfterVersionNumber);
	If BeforeVersionNumber = Undefined Then
		ShowMessageBox(,NStr("ru='Предыдущая версия отсутствует';SYS='DataHistory.PreviousVersionNotExists'", "ru"));
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert(GetCurrentName("Data"), Parameters.Data);
	FormParameters.Insert(GetCurrentName("VersionNumberAfterChange"), AfterVersionNumber);
	FormParameters.Insert(GetCurrentName("VersionNumberBeforeChange"), BeforeVersionNumber);

	OpenForm(GetFormNameByMetadata("DataHistoryVersionDifferencesForm"), FormParameters);
EndProcedure

&AtClient
Procedure SwitchToVersion(Command)
	If Not CheckSelectedVersion() Then
		Return;
	EndIf;
	
	OpenForm(GetFormNameSwitchToVersion(), New Structure(
		"Key, VersionNumberSwitchToDataHistoryVersion", 
		Parameters.Data, 
		Items.Versions.CurrentData.VersionNumber));
EndProcedure
	
&AtServerNoContext
Procedure WriteComment(Data, VersionNumber, Comment)
	DataHistory.WriteComment(Data, VersionNumber, Comment);
EndProcedure

&AtClient
Procedure VersionsCommentOnChange(Item)
	Var Version;
	Version = Items.Versions.CurrentData;
	If Version <> Undefined Then
		WriteComment(Parameters.Data, Version.VersionNumber, Version.Comment);
	EndIf;
EndProcedure

&AtClient
Function CheckSelectedVersion()
	If Items.Versions.CurrentData = Undefined Then
		ShowMessageBox(,NStr("ru='Выберите версию';SYS='DataHistory.SelectVersionsVersion'", "ru"));
		Return False;
	EndIf;
	If Items.Versions.CurrentData.DataChangeType = 2 Then
		ShowNotAllowedActionsOnDeletedVersion();
		Return False;
	EndIf;
	Return True;
EndFunction

&AtClient
Procedure ShowNotAllowedActionsOnDeletedVersion()
	ShowMessageBox(,NStr("ru='Нельзя выполнять действия с версией, соответствующей удалению данных';SYS='DataHistory.NotAllowedActionsOnDeletedVersion'", "ru"));
EndProcedure

&AtServer
Function GetDataPresentation(DataMetadata, Data)
	Var Presentation, Separator;
	If Metadata.InformationRegisters.Contains(DataMetadata) Then
		Presentation = "";
	
		If DataMetadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
			If DataMetadata.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition
				Or DataMetadata.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.Second Then
				Presentation = DataMetadata.StandardAttributes.Period.Presentation() + "=" + String(Data.Period);
			Else
				Presentation = DataMetadata.StandardAttributes.Period.Presentation() + "=" + Format(Data.Period, "DLF=D");
			EndIf;
		EndIf;
		
		If DataMetadata.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition Then
			If Not IsBlankString(Presentation) Then
				Presentation = Presentation + ";"
			EndIf;
			Presentation = Presentation + DataMetadata.StandardAttributes.Recorder.Presentation() + "=" + String(Data.Recorder);
		EndIf;
		
		For Each Dimension In DataMetadata.Dimensions Do
			If Not IsBlankString(Presentation) Then
				Presentation = Presentation + ";"
			EndIf;
			Presentation = Presentation + String(Dimension) + "=" + String(Data[Dimension.Name]);
		EndDo;
		
		For Each CommonAttribute In Metadata.CommonAttributes Do
			If 	CommonAttribute.DataSeparation <> Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate
				Or CommonAttribute.SeparatedDataUse <> Metadata.ObjectProperties.CommonAttributeSeparatedDataUse.IndependentlyAndSimultaneously Then
				Continue;
			EndIf;
			
			Separator = CommonAttribute.Content.Find(DataMetadata);
			If 		Separator = Undefined
				Or 	Separator.Use = Metadata.ObjectProperties.CommonAttributeUse.DontUse
				Or (Separator.Use = Metadata.ObjectProperties.CommonAttributeUse.Auto
					And CommonAttribute.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.DontUse) Then
				Continue;
			EndIf;

			If Not IsBlankString(Presentation) Then
				Presentation = Presentation + ";"
			EndIf;
			
			Presentation = Presentation + String(CommonAttribute) + "=" + String(Data[CommonAttribute.Name]);
		EndDo;
		
		Return Presentation;
	ElsIf Metadata.Constants.Contains(DataMetadata) Then
		Return DataMetadata.Presentation();
	Else
		Return String(Data);
	EndIf;
EndFunction