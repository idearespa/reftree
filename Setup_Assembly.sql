-- 1. preparazione database per installazione assembly
use reftree
go
alter database reftree
  set trustworthy on;
go

-- 2. Creazione assembly dopo aver definito la directory in cui verrà copiato il file
create assembly CustomProcedures from '<nome_percorso_assembly>\CustomProcedures.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS --SAFE, UNSAFE
GO

-- 3. Creazione funzioni e sp
create assembly CustomProcedures from 'C:\Program Files\Microsoft SQL Server\MSSQL\CustomCLRProcs\CustomProcedures.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS --SAFE, UNSAFE
GO

create assembly [System.Runtime.Serialization] 
authorization dbo
from  N'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Runtime.Serialization.dll'
with permission_set = unsafe
go

CREATE ASSEMBLY [Newtonsoft.Json]
AUTHORIZATION dbo
FROM  N'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Newtonsoft.Json.dll'
WITH PERMISSION_SET = UNSAFE
go

create assembly jsonLib from 'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Binn\clrDll\jsonLib.dll'
WITH PERMISSION_SET =  UNSAFE
go

/****** Object:  UserDefinedFunction [dbo].[f_charCount]    Script Date: 10/09/2014 12:22:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_charCount]
    (
     @string [nvarchar](max)
    ,@strToSearch [nvarchar](10)
    )
returns [int]
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[CharCount]
go

/****** Object:  UserDefinedFunction [dbo].[f_CryptString]    Script Date: 10/09/2014 12:22:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_CryptString]
    (
     @inputString [nvarchar](max)
    )
returns [nvarchar](max)
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_Crypta]
go

/****** Object:  UserDefinedFunction [dbo].[f_delete_file]    Script Date: 10/09/2014 12:22:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_delete_file]
    (
     @filename [nvarchar](max)
    )
returns [int]
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_DeleteFile]
go

/****** Object:  UserDefinedFunction [dbo].[f_file_copy]    Script Date: 10/09/2014 12:22:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_file_copy]
    (
     @srcPathFileName [nvarchar](max)
    ,@tgtPath [nvarchar](max)
    ,@tgtFileName [nvarchar](max)
    )
returns [bit]
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[CopyFile]
go

/****** Object:  UserDefinedFunction [dbo].[f_rep_cons_or_vow]    Script Date: 10/09/2014 12:22:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_rep_cons_or_vow]
    (
     @string [nvarchar](max)
    ,@consonante [bit]
    )
returns [nvarchar](4000)
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_DelVowelOrCons]
go

/****** Object:  UserDefinedFunction [dbo].[f_search_text]    Script Date: 10/09/2014 12:22:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_search_text]
    (
     @pathFile [nvarchar](max)
    ,@textToFind [nvarchar](max)
    )
returns [bit]
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_FindText]
go

/****** Object:  UserDefinedFunction [dbo].[f_splitString]    Script Date: 10/09/2014 12:22:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_splitString]
    (
     @inputString [nvarchar](1000)
    ,@splitChar [nchar](1)
    ,@livello [int]
    )
returns [nvarchar](1000)
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[SplitString]
go

/****** Object:  UserDefinedFunction [dbo].[f_test_exist_file]    Script Date: 10/09/2014 12:22:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_test_exist_file]
    (
     @filename [nvarchar](4000)
    )
returns [int]
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[TestFiles]
go

/****** Object:  UserDefinedFunction [dbo].[f_test_exist_folder]    Script Date: 10/09/2014 12:22:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_test_exist_folder]
    (
     @folderName [nvarchar](max)
    )
returns [int]
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[TestFolders]
go

/****** Object:  UserDefinedFunction [dbo].[f_write_file]    Script Date: 10/09/2014 12:22:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_write_file]
    (
     @filename [nvarchar](max)
    ,@Text [nvarchar](max)
    )
returns [bit]
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_WriteFile]
go

/****** Object:  UserDefinedFunction [dbo].[f_write_file_no_ascii]    Script Date: 10/09/2014 12:22:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_write_file_no_ascii]
    (
     @filename [nvarchar](max)
    ,@Text [nvarchar](max)
    ,@encoding [smallint]
    )
returns [bit]
    with execute as caller
/*******************************************************
** Il parametro encoding accetta i seguenti valori:
** 1 --> Unicode 
** 2 --> UTF8 
** 3 --> UTF7 
** 4 --> UTF32
** Else Ascii
*******************************************************/
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_WriteFile_no_ascii]
go

/****** Object:  UserDefinedFunction [dbo].[f_write_file2]    Script Date: 10/09/2014 12:22:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_write_file2]
    (
     @filename [nvarchar](max)
    ,@Text [nvarchar](max)
    )
returns [bit]
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_WriteFile2]
go

/****** Object:  UserDefinedFunction [dbo].[f_read_file]    Script Date: 10/09/2014 12:22:50 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_read_file]
    (
     @filename [nvarchar](max)
    )
returns table
    (
     [riga] [nvarchar](max) null
    )
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_ReadFileMultiLine]
go

/****** Object:  StoredProcedure [dbo].[usp_exec_auton_tran_stmt]    Script Date: 10/09/2014 12:23:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create procedure [dbo].[usp_exec_auton_tran_stmt]
    @sqlStmt [nvarchar](max)
   ,@dbname [nvarchar](128)
   ,@retCode [smallint] output
   ,@retMsg [nvarchar](max) output
   ,@isoLevel [smallint] = 2
    with execute as caller
/*******************************************************
** Il parametro isolevel prevede i seguenti valori:
** 1 --> read uncommitted 
** 2 --> read committed, è il default  
** 3 --> repeatable read
** 4 --> serializable
** 5 --> snapshot
*******************************************************/
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[ExecuteATStmt]
go

/****** Object:  UserDefinedFunction [dbo].[f_decrypt_string]    Script Date: 16/09/2014 18:19:59 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_decrypt_string]
    (
     @key [int]
    ,@string [nvarchar](max)
    )
returns [nvarchar](max)
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_decrypt]
go

/****** Object:  UserDefinedFunction [dbo].[f_encrypt_string]    Script Date: 16/09/2014 18:19:59 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_encrypt_string]
    (
     @key [int]
    ,@string [nvarchar](max)
    )
returns [nvarchar](max)
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_encrypt]
go

/****** Object:  UserDefinedFunction [dbo].[f_tb_parse_string]    Script Date: 16/09/2014 18:23:17 ******/
set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[f_tb_parse_string]
    (
     @string [nvarchar](max)
    ,@separator [nchar](1)
    )
returns table
    (
     [StringCol] [nvarchar](max) null
    )
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[ParseString]
go

set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[usf_xsltTransform]
    (
     @xmlData as xml
    ,@xsltTransform as xml
    )
returns xml
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.XSLTTransform].[fn_xsltTransform]
go

set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[usf_xsltTransform_from_file]
    (
     @xmlFile as nvarchar(max)
    ,@xsltFile as nvarchar(max) 
    )
returns xml
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.XSLTTransform].[fn_xsltTransformFromFile]
go

set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[utf_fileProperties]
    (
     @fileFullPath [nvarchar](max)
    )
returns table
    (
     [FileName] nvarchar(1000) null, 
	 [Extension] nvarchar(10) null, 
	 [Size] bigint null,
	 [Created] datetime null, 
	 [LastAccess] datetime null, 
	 [LastWritten] datetime null
    )
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[utf_fileProperties]
go

set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[utf_filePropertiesArray]
    (
     @tgtDir as nvarchar(max),
	 @fileName [nvarchar](max), -- list of files separated by | character if @fileName = '' then search on whole dir by searchPattern
	 @searchPattern nvarchar(50)  -- es. *.txt, *.log
    )
returns table
    (
     [FileName] nvarchar(1000) null, 
	 [Size] bigint null,
	 [Created] datetime null,
	 Extension nvarchar(50) null,
	 [Exists] bit,
	 IsReadOnly bit,
	 LastAccess datetime,
	 LastWritten datetime
    )
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[utf_filePropertiesArray]
go

set ansi_nulls off
go

set quoted_identifier off
go

create function dbo.utf_directoryInfo 
    (
	 @tgtDir as nvarchar(max),
	 @searchPattern nvarchar(50)	  
	)
returns table
    (
     [Name] nvarchar(1000),
	 [IsDirectory]   bit,
	 [SizeInBytes]	 bigint,
	 [CreateDate]	 datetime,
	 [LastWritten]	 datetime,
	 [LastAccessed]	 datetime,
	 [Attributes]    nvarchar(4000)
    )
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[utf_directoryInfo]
go

set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[clr_Util_DecodeFromBase64]
    (
      @encodedData as nvarchar(max)
    )
returns varbinary(max)
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_base64_decode]
go

set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[clr_Util_GUnzip]
    (
      @data as varbinary(max)
    )
returns varbinary(max)
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_Util_GUnzip]
go

set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[clr_Util_WriteFileFromBytes]
    (
      @pathFile as nvarchar(4000)
     ,@contentData as varbinary(max)
    )
returns bit
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_Util_WriteFileFromBytes]
go

set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[clr_Util_ConvertFileToBinary]
    (
      @pathFile as nvarchar(4000)
    )
returns varbinary(max)
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_Util_ConvertFileToBinary]
go

set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[clr_Util_GZipBinaryFile]
    (
      @binaryFile as varbinary(max)
    )
returns varbinary(max)
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_Util_GZipBinaryFile]
go

set ansi_nulls off
go

set quoted_identifier off
go

create function [dbo].[clr_Base64_Encode]
    (
      @binaryFile as varbinary(max)
    )
returns nvarchar(max)
    with execute as caller
as external name
    [CustomProcedures].[CustomProcedures.FilesManager].[fn_base64_encode]
go

-- 4. Creazione sinonimi

/****** Object:  Synonym [dbo].[f_charCount]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_charCount') is null
	create synonym [dbo].[f_charCount] for [reftree].[dbo].[f_charCount]
go

/****** Object:  Synonym [dbo].[f_CryptString]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_CryptString') is null
	create synonym [dbo].[f_CryptString] for [reftree].[dbo].[f_CryptString]
go

/****** Object:  Synonym [dbo].[f_decrypt_string]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_decrypt_string') is null
	create synonym [dbo].[f_decrypt_string] for [reftree].[dbo].[f_decrypt_string]
go

/****** Object:  Synonym [dbo].[f_del_cons_vow]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_del_cons_vow') is null
	create synonym [dbo].[f_del_cons_vow] for [reftree].[dbo].[f_rep_cons_or_vow]
go

/****** Object:  Synonym [dbo].[f_delete_file]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_delete_file') is null
	create synonym [dbo].[f_delete_file] for [reftree].[dbo].[f_delete_file]
go

/****** Object:  Synonym [dbo].[f_encrypt_string]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_encrypt_string') is null
	create synonym [dbo].[f_encrypt_string] for [reftree].[dbo].[f_encrypt_string]
go

/****** Object:  Synonym [dbo].[f_FileCopy]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_FileCopy') is null
	create synonym [dbo].[f_FileCopy] for [reftree].[dbo].[f_file_copy]
go

/****** Object:  Synonym [dbo].[f_FileWriteLine]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_FileWriteLine') is null
	create synonym [dbo].[f_FileWriteLine] for [reftree].[dbo].[f_write_file]
go

/****** Object:  Synonym [dbo].[f_read_file]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_read_file') is null
	create synonym [dbo].[f_read_file] for [reftree].[dbo].[f_read_file]
go

/****** Object:  Synonym [dbo].[f_splitString]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_splitString') is null
	create synonym [dbo].[f_splitString] for [reftree].[dbo].[f_splitString]
go

/****** Object:  Synonym [dbo].[f_tb_parse_string]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_tb_parse_string') is null
	create synonym [dbo].[f_tb_parse_string] for [reftree].[dbo].[f_tb_parse_string]
go

/****** Object:  Synonym [dbo].[f_test_exist_file]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_test_exist_file') is null
	create synonym [dbo].[f_test_exist_file] for [reftree].[dbo].[f_test_exist_file]
go

/****** Object:  Synonym [dbo].[f_test_exist_folder]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_test_exist_folder') is null
	create synonym [dbo].[f_test_exist_folder] for [reftree].[dbo].[f_test_exist_folder]
go

/****** Object:  Synonym [dbo].[f_val_string_array]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_val_string_array') is null
	create synonym [dbo].[f_val_string_array] for [reftree].[dbo].[f_splitString]
go

/****** Object:  Synonym [dbo].[f_write_file_no_ascii]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'f_write_file_no_ascii') is null
	create synonym [dbo].[f_write_file_no_ascii] for [reftree].[dbo].[f_write_file_no_ascii]
go

/****** Object:  Synonym [dbo].[usp_exec_auton_tran_stmt]    Script Date: 10/09/2014 12:29:43 ******/
if object_id(N'usp_exec_auton_tran_stmt') is null
	create synonym [dbo].[usp_exec_auton_tran_stmt] for [reftree].[dbo].[usp_exec_auton_tran_stmt]
go

if object_id(N'usf_xslt_transform') is null
	create synonym [dbo].[usf_xslt_transform] for [reftree].[dbo].[usf_xsltTransform]
go

if object_id(N'usf_xsltTransform_from_file') is null
	create synonym [dbo].[usf_xsltTransform_from_file] for [reftree].[dbo].[usf_xsltTransform_from_file]
go

if object_id(N'utf_fileProperties') is null
	create synonym [dbo].[utf_fileProperties] for [reftree].[dbo].[utf_fileProperties]
go

if object_id(N'utf_filePropertiesArray') is null
	create synonym [dbo].[utf_filePropertiesArray] for [reftree].[dbo].[utf_filePropertiesArray]
go

if object_id(N'utf_directoryInfo') is null
	create synonym [dbo].[utf_directoryInfo] for [reftree].[dbo].[utf_directoryInfo]
go

if object_id(N'clr_Util_DecodeFromBase64') is null
	create synonym [dbo].[clr_Util_DecodeFromBase64] for [reftree].[dbo].[clr_Util_DecodeFromBase64]
go

if object_id(N'clr_Util_GUnzip') is null
	create synonym [dbo].[clr_Util_GUnzip] for [reftree].[dbo].[clr_Util_GUnzip]
go

if object_id(N'clr_Util_WriteFileFromBytes') is null
	create synonym [dbo].[clr_Util_WriteFileFromBytes] for [reftree].[dbo].[clr_Util_WriteFileFromBytes]
go

if object_id(N'clr_Util_ConvertFileToBinary') is null
	create synonym dbo.clr_Util_ConvertFileToBinary for reftree.dbo.clr_Util_ConvertFileToBinary
go	

if object_id(N'clr_Util_GZipBinaryFile') is null
	create synonym dbo.clr_Util_GZipBinaryFile for reftree.dbo.fn_Util_GZipBinaryFile
go

if object_id(N'clr_Base64_Encode') is null
	create synonym dbo.clr_Base64_Encode for reftree.dbo.clr_Base64_Encode
go	

