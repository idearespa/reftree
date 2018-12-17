/****** Object:  Table [dbo].[AQ_ACCESS_DB]    Script Date: 17/12/2018 15:32:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[AQ_ACCESS_DB](
	[AQ_ACCESS_ID] [int] IDENTITY(1,1) NOT NULL,
	[AQ_ACCESS_CODFISC] [nvarchar](50) NOT NULL,
	[AQ_ACCESS_NR_TENT] [int] NULL,
	[AQ_ACCESS_CELL] [nvarchar](500) NULL,
	[AQ_ACCESS_PSW] [nvarchar](60) NOT NULL,
	[AQ_ACCESS_REG_DATE] [datetime] NULL,
	[AQ_ACCESS_VALIDATED] [bit] NULL,
 CONSTRAINT [PK_AQ_ACCESS_DB] PRIMARY KEY CLUSTERED 
(
	[AQ_ACCESS_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[AQ_ACCESS_DB] ADD  CONSTRAINT [DF_validation_check]  DEFAULT ((0)) FOR [AQ_ACCESS_VALIDATED]
GO






/****** Object:  StoredProcedure [dbo].[aequa_update_account]    Script Date: 17/12/2018 15:31:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[aequa_update_account] (@xmlInput xml)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/*
	<root>
	   <user>
		  <codiceFiscale>a</codiceFiscale>
	   </user>
	   <input>
		  <numeroCellulare>84848484</numeroCellulare>
	   </input>
	</root>
	*/
    declare @codice_fiscale nvarchar(50) = @xmlInput.value('(/root/user/codiceFiscale)[1]', 'nvarchar(50)');
    declare @numeroCellulare as nvarchar(20) = @xmlInput.value('(/root/input/numeroCellulare)[1]', 'nvarchar(20)');

	declare @skebbyUser as varchar(50) =  'aequaroma'; --'Ideare' --
	declare @skebbyPwd as varchar(50) =   'Ostiense131'; --'VialeLiegi41'  --

	declare @debug as bit = 0;
	declare @smsOutMsg as nvarchar(max) = N'';  

	declare @msg as nvarchar(1000) = N'Numero di cellulare registrato correttamente.' 

	declare @smsType as nvarchar(255) = N'send_sms_classic_report';
	declare @ERRORE nvarchar(max);

	if left(@numeroCellulare, 1 ) = '+' or
		left(@numeroCellulare, 2) = '00'
	   begin
	       set @ERRORE = N'Inserire il numero di telefono senza prefisso internazionale';
		   throw 51000, @ERRORE, 1; -- errore viene mostrato all'utente
           return;
	   end;

	if @debug = 0
		begin
		    set  @smsOutMsg = dbo.usf_SendSms(@skebbyUser, @skebbyPwd, '39' + replace(@numeroCellulare,' ',''), @msg, @smsType);
		end 		   
	else
		begin 
			set @smsType = N'test_send_sms_classic_report';
		    set  @smsOutMsg = dbo.usf_SendSms(@skebbyUser, @skebbyPwd, '39' + replace(@numeroCellulare,' ',''), @msg, @smsType);		       
		end  
		  
	if @smsOutMsg != 'success'
	   begin
	        set @smsOutMsg = @smsOutMsg + N'. Nessuna modifica è stata effettuata';
	        throw 51000, @smsOutMsg, 1;
	   end

	if @debug = 1
		begin
            set  @msg = @msg + N' Il nuovo numero è +39' + @numeroCellulare;
			exec dbo.RG_SEND_MAIL @from = null   -- sysname
								, @to = 'marco.fusco@idearespa.eu'       -- varchar(max)
								, @subject = N'Credenziali aequaroma' -- nvarchar(255)
								, @body = @msg   -- nvarchar(max)
								, @cc = ''       -- varchar(max)
								, @cn = ''       -- varchar(max)
		       
		end 	
		 
	--THROW 51000, 'update fallito', 1; -- errore viene mostrato all'utente
	if exists (select 1 from dbo.AQ_ACCESS_DB
			   where  AQ_ACCESS_CODFISC = @codice_fiscale)
	   update dbo.AQ_ACCESS_DB
	   set    AQ_ACCESS_CELL = @numeroCellulare
	   where  AQ_ACCESS_CODFISC = @codice_fiscale;    

    -- Insert statements for procedure here
	SELECT @msg AS 'message';
END
GO

/****** Object:  StoredProcedure [dbo].[aequa_download]    Script Date: 17/12/2018 15:31:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create procedure  [dbo].[aequa_download] 
      (@xmlInput as xml)
as
/*******************************************************************************
** Version: 1.0
** Name: 	aequa_download
** Schema:  dbo
** Desc:    Returns a table with: size_in_bytes, fileName and file in varbinary
**
** Table:   temporary table
**
** Auth: 	Marco
** Date: 	07/03/2018
*******************************************************************************
** Change History
*******************************************************************************
** Date:               Author:         Description:
** 
*******************************************************************************/
/*
	<root>
		<user>
			<codiceFiscale>a</codiceFiscale>
		</user>
		<input>
			<id>1</id>
		</input>
	 </root>
*/
declare @fatattId as int = @xmlInput.value('(/root/input/id)[1]','int');    
declare @fileName as varchar(max) =  (select  replace(isnull(ft.FATATT_LINK_OGGETTO_1,ft.FATATT_LINK_OGGETTO ), '&#47;', '\')
									  from    dbo.FATATT_fatture_attive ft
									  where   ft.FATATT_ID = @fatattId);
declare @filePath as varchar(max) = dbo.F_DETERMINA_PATH_FILE('File output', null);
declare @fileFullPath as varchar(max) = @filePath + @fileName;

declare @contentFile as varbinary(max); 
declare @sqlCmd as nvarchar(max) = 'select @contentFile = fileContent from openrowset(bulk N' + char(39) + @fileFullPath + char(39) + ', SINGLE_BLOB) as tbl(fileContent)';
declare @cleanFileName as varchar(max);
declare @id as int;

--print @sqlCmd;

exec sp_executesql @sqlCmd, N'@contentFile as varbinary(max) output', @contentFile output;

declare @size_in_bytes as bigint = (select Size from dbo.utf_fileProperties(@fileFullPath));

declare @output as table (size_in_bytes bigint, name varchar(250), [file] varbinary(max) );

if charindex('\',@fileName) > 0
	begin 
	    select top 1 @id = row_number() over (order by StringCol), 
		       @cleanFileName = StringCol
		from   dbo.f_tb_parse_string(@fileName,'\') 
		where  StringCol != '';

	end 
else 
    begin 
        set @cleanFileName = @fileName;
    end 

insert into @output ( size_in_bytes
                    , name
                    , [file] )
values ( @size_in_bytes    -- size_in_bytes - bigint
       , @cleanFileName   -- name - varchar(250)
       , @contentFile -- file - varbinary(max)
    )
select  * from @output;
GO

/****** Object:  StoredProcedure [dbo].[aequa_data]    Script Date: 17/12/2018 15:31:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[aequa_data]
    (
        @xmlInput xml
    )
as
    begin
		-- Per individuare le modifiche di ottobre 2018, vedere i commenti con il testo "OTTOBRE_2018"
		
        -- SET NOCOUNT ON added to prevent extra result sets from
        -- interfering with SELECT statements.

        /* input
	<root>
	   <user>
		  <codiceFiscale>a</codiceFiscale>
	   </user>
	   <input>
		  <gridName>sepp</gridName>
	   </input>
	</root>
	*/
        set nocount on;
        declare @conloc_id int;
        declare @conloc_codice nvarchar(50);
        declare @codice_fiscale nvarchar(max) = @xmlInput.value(
                                                              '(/root/user/codiceFiscale)[1]'
                                                            , 'nvarchar(max)');

        declare @pathFile as varchar(max) = dbo.F_DETERMINA_PATH_FILE(
                                                'File output' , null);
		
		declare @response varchar(8000),@responseXML XML;
		declare @vcUrl varchar(2000);
		DECLARE @Path VARCHAR(50),
				@file VARCHAR(500),
				@newfilename VARCHAR(500),
				@iRetCopy BIT,
				@error_code VARCHAR(500);
		declare @d DATETIME = GETDATE();
		-- "OTTOBRE_2018", 26 ottobre 2018: Richiesta gestione totale residuo (se negativo, non mostrare estratto conto ma un messaggio)
		declare @errore as nvarchar(2000);
		declare @totaleResiduo decimal(18, 2);
		set @totaleResiduo = 0;
        
		select ANAGRA_ID
        into   #tb_anagra
        from   dbo.ANAGRA_anagrafica afa
        where  afa.ANAGRA_CODICE_FISCALE = @codice_fiscale or afa.ANAGRA_PARTITA_IVA = @codice_fiscale ;


        select CONLOC_ID
             , CONLOC_CODICE
        into   #tb_conloc
        from   #tb_anagra ta
               inner join dbo.CONLOC_contratto_di_locazione cl on cl.CONLOC_ANAGRA_ID = ta.ANAGRA_ID;
		
		
		--INTEGRAZIONE STAMPE BOLLETTINI IUV (ove presenti, potrebbe dare errore se già pagato!)
		DECLARE @IUV as varchar(30), @ID INT;
        
        DECLARE cur CURSOR FAST_FORWARD READ_ONLY LOCAL FOR
        	SELECT FATATT_AVVISO_PAGAMENTO,FATATT_ID
        	FROM dbo.FATATT_fatture_attive
			inner JOIN #tb_conloc ON FATATT_CONLOC_ID=CONLOC_ID
			WHERE FATATT_DATA_CONTABILIZZAZIONE>='20180201' AND FATATT_LINK_OGGETTO_1 is null and FATATT_AVVISO_PAGAMENTO!=FATATT_ID
				AND FATATT_AVVISO_PAGAMENTO is not NULL
				AND (isnull(fatatt_importo,0) - isnull(fatatt_importo_pagato,0) - isnull(fatatt_importo_stornato,0) + (isnull(fatatt_importo_rate_emesse,0) -isnull(dbo.r2_fu_newec_rateizzato(fatatt_id,'pem'),0)))>0
        
		open cur;
        
        --FETCH NEXT FROM cur INTO @IUV,@ID
        
        WHILE 10 = 10
		    begin
			
			FETCH NEXT FROM cur INTO @IUV,@ID
			
			if @@FETCH_STATUS != 0
			   BEGIN
			       deallocate cur;
				   break;
			   END
			
			set @vcUrl = 'http://10.173.9.46:8014/richBollettino.aspx?MIT=PTR&SER=&CAN=&TKN=1&TIDE=E0001&IDE='+@IUV+'&AMB=1'


			exec dbo.HTTP_REQUEST @vcUrl
							 ,@response output;

			select @responseXML=CAST(@response as XML);

			SELECT  @Path=CAST(@responseXML.query('data(/RISULTATO/PATH[1])') as VARCHAR(500)),
					@file=CAST(@responseXML.query('data(/RISULTATO/FILE[1])') as VARCHAR(500)),
					@error_code=cast(@responseXML.query('data(/RISULTATO/ERRORE[1])') as VARCHAR(500));
			SET @error_code=dbo.F_CONVERTI_NULL(@error_code);

			INSERT INTO ws_aequa_log_print (ws,errorCode)
			VALUES (@vcUrl,@error_code);

        	IF @error_code is NULL AND dbo.f_test_exist_file(@Path+@file)=1
			begin
	
				SET @newfilename=replace(convert(varchar(8), @d, 112)+convert(varchar(8), @d, 114), ':','')+'_'+@IUV+'.pdf';
				
				SELECT @iRetCopy=dbo.f_FileCopy(@path+@file,dbo.F_DETERMINA_PATH_FILE('file output',NULL),@newfilename);
				
			
					DECLARE @iRetDel INT;
					SELECT @iRetDel=dbo.f_delete_file(@path+@file);

			
						UPDATE FATATT_fatture_attive
						set FATATT_LINK_OGGETTO_1=@newfilename
						WHERE FATATT_ID=@ID;
			 END;
        	--FETCH NEXT FROM cur INTO @IUV,@ID
        
			END;
			
        
        --CLOSE cur
        --DEALLOCATE cur
		--FINE INTEGRAZIONE STAMPE IUV
		

        if @xmlInput.value('(/root/input/gridName)[1]', 'nvarchar(10)') = 'grid1'
            --THROW 51000, 'geageageagaegea', 1;
            begin
                select tbc.CONLOC_CODICE as codice
					 ,case	when fta.fatatt_note in ('canone','oneri','rateizzo') Then tf.TIPFAT_DESCRIZIONE + ' ('+ fatatt_note +')' 
							Else tf.TIPFAT_DESCRIZIONE 
							End 
					 as tipo
                     , fta.FATATT_DATA_CONTABILIZZAZIONE
					 /*
					 cast(month(
                                    [FATATT_DATA_CONTABILIZZAZIONE]) as varchar(2))
                            + '/'
                            + cast(year(
                                        [FATATT_DATA_CONTABILIZZAZIONE]) as varchar(4)) 
					*/					
						as data
					-- "OTTOBRE_2018", 24 ottobre 2018: Richiesta modifica formato data
					, convert(varchar(10),FORMAT( fta.FATATT_DATA_SCADENZA, 'yyyy/MM/dd', 'en-US' ),103) as scadenza	
                     --, fta.FATATT_DATA_SCADENZA--convert(varchar(11), fta.FATATT_DATA_SCADENZA, 103) 
					--	as scadenza
        --             , FATATT_IMPORTO
        --               + isnull(fta.FATATT_IMPORTO_RATE_EMESSE, 0)
        --               -- isnull(FATATT_IMPORTO_PAGATO, 0) 
					   --as importo
					 , '€ '+replace(dbo.R2_FU_NEWEC_AVVISO_PAGAMENTO_PV(FATATT_ID,'RIC'),'.',',') as importo
                     --, cast('Stampa' as varchar(100)) as button
                     , button = case when isnull(
                                              fta.FATATT_LINK_OGGETTO_1
                                            , fta.FATATT_LINK_OGGETTO) is not null 
									 then
                                         case when dbo.f_test_exist_file(@pathFile+ replace(isnull(fta.FATATT_LINK_OGGETTO_1, fta.FATATT_LINK_OGGETTO), '&#47;', '\')) = 1  then
                                                  '<a class="btn btn-secondary" href="/api/download?id='+ cast(fta.FATATT_ID as varchar)+ '" target="_blank">Download</a>'
                                             else ''
                                          end
                                     else ''
                                end
                from   #tb_conloc tbc
                       inner join dbo.FATATT_fatture_attive fta on fta.FATATT_CONLOC_ID = tbc.CONLOC_ID
                       inner join dbo.TIPFAT_tipologia_fatture tf on tf.TIPFAT_CODICE = fta.FATATT_TIPFAT_CODICE
                where (isnull(fta.fatatt_importo,0) - isnull(fta.fatatt_importo_pagato,0) - isnull(fta.fatatt_importo_stornato,0) + (isnull(fta.fatatt_importo_rate_emesse,0) -isnull(dbo.r2_fu_newec_rateizzato(fta.fatatt_id,'pem'),0)))>0
					   -- and dbo.f_test_exist_file(@pathFile+ replace(isnull(fta.FATATT_LINK_OGGETTO_1, fta.FATATT_LINK_OGGETTO), '&#47;', '\')) = 1 
						and 
						(
							( 
							fta.FATATT_LINK_OGGETTO is not null and  fta.FATATT_MODPAG_CODICE != 'PA' AND fta.FATATT_LINK_OGGETTO LIKE '%.pdf%'
							) 
							or 
							(
							/*fta.FATATT_LINK_OGGETTO_1 is not null AND*/  fta.FATATT_MODPAG_CODICE = 'PA' AND FATATT_AVVISO_PAGAMENTO!=FATATT_ID AND FATATT_AVVISO_PAGAMENTO is not NULL
							)
						)
				order by FATATT_DATA_CONTABILIZZAZIONE desc, FATATT_DATA_SCADENZA desc;


                -- optional second select to provide config for datatable
                select '{"columns":[{"name":"Codice Contratto","data":"codice"},{"name":"Documento","data":"tipo"},{"name":"Competenza","data":"data","type":"date"},{"name":"Scadenza","data":"scadenza","type":"date"},{"name":"Importo Bollettino","data":"importo","className": "text-right"},{"name":"Stampa bollettino","data":"button"}]}' as config, 'Bollette' as title;
            end;
        else if @xmlInput.value('(/root/input/gridName)[1]', 'nvarchar(10)') = 'grid2'
                 begin

                     create table #Tb_fatatt
								 (
									 contratto	nvarchar(50)
								   , tipologia	nvarchar(500)
								   , data		datetime
								   , data2		datetime
								   , data3		datetime
								   , importo	decimal(18, 2)
								   --,importo2	decimal(18,2)
								   --,importo3	decimal(18,2)
								   --,importo4	decimal(18,2)
								   --,importo5	decimal(18,2)
								   --, importo6 decimal(18, 2)
								   , residuo	decimal(18, 2)
								 );


                     declare read_conloc cursor for
                         select CONLOC_ID
                              , CONLOC_CODICE
                         from   #tb_conloc;
                     open read_conloc;
                     fetch next from read_conloc
                     into @conloc_id
                        , @conloc_codice;
                     while @@fetch_status = 0
                         begin
                             insert into #Tb_fatatt ( contratto
                                                    , tipologia
                                                    , data
                                                    , data2 
                                                    , data3 
                                                    , importo
                                                    --importo2 
                                                    --importo3 
                                                    --,importo4 
                                                    --,importo5 
                                                    --,importo6
                                                    , residuo )
                                         select   @conloc_codice as contratto
                                                , case	when fta.fatatt_note in ('canone','oneri','rateizzo') then tf.tipfat_descrizione + ' ('+ fta.fatatt_note  +')' 
														else tf.tipfat_descrizione
														end 
												     as tipologia
                                                -- "OTTOBRE_2018", 24 ottobre 2018: Richiesta modifica formato data
											   -- , convert(varchar(11),fta.fatatt_data_fattura,103) as data
												, convert(varchar(10),FORMAT( fta.fatatt_data_fattura, 'yyyy/MM/dd', 'en-US' ),103) as data
													
                                                , fta.fatatt_data_contabilizzazione
													/*
												  cast(month(
                                                           [fatatt_data_contabilizzazione]) as varchar(2))
                                                  + '/'
                                                  + cast(year(
                                                             fta.fatatt_data_contabilizzazione) as varchar(4))
													*/ 
												as data2
												-- "OTTOBRE_2018", 24 ottobre 2018: Richiesta modifica formato data
											   -- , convert(varchar(11),fta.fatatt_data_scadenza,103) as data3
												, convert(varchar(10),FORMAT( fta.fatatt_data_scadenza, 'yyyy/MM/dd', 'en-US' ),103) as data3
                                                --, fta.fatatt_data_scadenza --convert(varchar(10),fta.fatatt_data_scadenza,103) 
												--	as data3
												, dbo.r2_fu_newec_avviso_pagamento_pv(fatatt_id,'ric') as importo
                                                --, isnull([fatatt_importo],0.00) as importo
                                                --, [fatatt_pagato]  as importo2
                                                --, [fatatt_stornato]	as importo3
                                                --, isnull([at_transa_importo_rateizzato],0.00)  as importo4
                                                --, [fatatt_importo_rimborsato] as importo5
                                                --, isnull(fatatt_importo_rate_emesse,0.00)  as importo6
                                                --, isnull(residuo,0.00)  as residuo
												,(isnull(fta.fatatt_importo,0) - isnull(fta.fatatt_importo_pagato,0) - isnull(fta.fatatt_importo_stornato,0) + (isnull(fta.fatatt_importo_rate_emesse,0) -isnull(dbo.r2_fu_newec_rateizzato(fta.fatatt_id,'pem'),0))) as residuo
                                         --from     dbo.PORTALE_VI_LOCA_NEWEC_ALL --[dbo].NEWEC_ALL
										 from 
												dbo.fatatt_fatture_attive fta 
												inner join dbo.tipfat_tipologia_fatture tf on tf.tipfat_codice = fta.fatatt_tipfat_codice
										 where  (isnull(fta.fatatt_importo,0) - isnull(fta.fatatt_importo_pagato,0) - isnull(fta.fatatt_importo_stornato,0) + (isnull(fta.fatatt_importo_rate_emesse,0) -isnull(dbo.r2_fu_newec_rateizzato(fta.fatatt_id,'pem'),0)))>0
												and     fatatt_conloc_id = @conloc_id  
												and fatatt_data_fattura > (cast(year(getdate())-3 as varchar(4))+cast(dbo.f_aggiungi_zeri(2,month(getdate())) as varchar(2))+'01')
                                         order by [fatatt_data_contabilizzazione] desc
                                                , fatatt_data_scadenza desc;
												
												-- "OTTOBRE_2018", 26 ottobre 2018: (appoggio per totale residuo: se negativo, non mostrare estratto conto ma un messaggio)		
										set @totaleResiduo = @totaleResiduo + (select residuo 
																				from   #Tb_fatatt);
												
                             fetch next from read_conloc
                             into @conloc_id
                                , @conloc_codice;
                         end;
                     close read_conloc;
                     select   contratto
							, tipologia
							, data 
							, data2 
							, data3 
							, '€ ' + cast(replace(importo,'.',',') as varchar(50)) as importo
							--, '€ ' + cast(replace(importo4,'.',',') as varchar(50)) as importo4   
							--, '€ ' + cast(replace(importo6,'.',',') as varchar(50)) as importo6  
							, '€ ' + cast(replace(residuo,'.',',') as varchar(50)) as residuo  
                     from   #Tb_fatatt;
				 /*
				 declare @BU as varchar(100)
				 select @BU = UNIIMM_CODICE  
				 from 
					 #tb_conloc
					 inner join UNILOC_unita_locativa 
						on UNILOC_CONLOC_ID = CONLOC_ID
					 inner join UNIIMM_unita_immobiliare
						on UNILOC_unita_locativa.UNILOC_UNIIMM_ID = UNIIMM_unita_immobiliare.UNIIMM_ID
				 where UNILOC_FLAG_PRINCIPALE = 1
				    
				 declare @totResiduo as varchar(100)
				 select @totResiduo = '€ ' + cast(replace(sum(residuo) ,'.',',') as varchar(50)) 
				    from   #Tb_fatatt;

				 declare @div nvarchar(1000)
				 set @div = '<span>' + '<b>' + 'BU:' + '</b>' +'<input style="text-align: right;" value="'+ @BU + '" readonly></input></span>'
				 set @div = @div + '<span>' + '<b>' + 'Saldo Contabile:' + '</b>' +'<input style="text-align: right;" value="'+ @totResiduo + '" readonly></input></span>'
				 --set @div = @div + '<span>' + '<b>' + 'Saldo Contabile:' + '</b>' +'<input style="text-align: right;" value="'+ @totResiduo + '" readonly></input></span>'
				 --set @div = @div + '<span>' + '<b>' + 'Saldo Contabile:' + '</b>' +'<input style="text-align: right;" value="'+ @totResiduo + '" readonly></input></span>'
				  */
                 -- "OTTOBRE_2018", 26 ottobre 2018: (controllo per totale residuo: se negativo, non mostrare estratto conto ma un messaggio)		
				  -- test per prove: set @totaleResiduo = -1;
				  if @totaleResiduo < 0
				  -- "OTTOBRE_2018", 26 ottobre 2018: (errore fittizio per totale residuo: se negativo, non mostrare estratto conto ma un messaggio)		
						begin
							set @errore = N'Errore! Operazione non disponibile, per maggiori dettagli si prega di recarsi allo sportello';
							throw 51000, @errore, 1;
							return;
						end;
				  else		 
					 select /*@div  as   buttons, */
					 '{"columns":[{"name":"Codice Contratto","data":"contratto"},{"name":"Documento","data":"tipologia"},{"name":"Data Emissione","data":"data"},{"name":"Competenza","data":"data2"},{"name":"Data Scadenza","data":"data3"},{"name":"Importo Bollettato","data":"importo"},{"name":"Importo da Pagare","data":"residuo"}]}' as config, 'Conto' as title;
				  
						
				  end;
        else if @xmlInput.value('(/root/input/gridName)[1]', 'nvarchar(10)') = 'grid3'
                 begin
						
                     create table #Tb_ccomov
                         (
                              codice		nvarchar(50)
							, operazione	datetime
							, versato		decimal(18,2)
							, descrizione	nvarchar(500)
							, numero		nvarchar(500)
							, versante		nvarchar(500)
                         );
					insert into #Tb_ccomov
                         (
                              codice  
							, operazione  
							, versato  
							, descrizione  
							, numero  
							, versante  
                         )
                      
						select   tbc.conloc_codice as codice,
								ccomov_data_operazione   as operazione, 
								ccomov_dare   as versato, 
								--ccomov_tipo_postel as tipo,
								--ccomov_quarto_campo_postel as  campo,
								concor_descrizione as descrizione, 
								concor_numero as numero,
								ccomov_versante as versante --,
								--isnull(ccomov_importo_a_deposito,0) as deposito, 
								--isnull(ccomov_importo_a_fattura,0) as fattura ,
								--isnull(ccomov_importo_anticipo,0) as anticipo,
								--isnull(ccomov_importo_a_rimborso,0) as rimborso,
								--ccomov_residuo_attribuibile as residuo
						from #tb_conloc tbc 
								inner join dbo.PORTALE_VI_LOCA_CCOMOV	on ccomov_conloc_id = tbc.conloc_id
						where     (ccomov_dare >0)
						Order by 2 desc;

					  select  codice
							,  operazione
							, '€ ' + cast(replace(versato ,'.',',') as varchar(50)) versato 
							, descrizione 
							, numero 
							, versante
                     from   #Tb_ccomov;
                     select  '{"columns":[{"name":"Codice Contratto","data":"codice"},{"name":"Data Versamento","data":"operazione","type":"date"},{"name":"Importo Versamento","data":"versato","className": "text-right"}, {"name":"Descrizione Conto Corrente","data":"descrizione"},{"name":"Numero Conto","data":"numero"},{"name":"Versante","data":"versante"}]}' as config, N'Comunicazioni' as title;
                 end;
		
        else if @xmlInput.value('(/root/input/gridName)[1]', 'nvarchar(10)') = 'grid4'
                 begin
						 create table #Tb_ric_comloc
									 (
										  contratto		nvarchar(50)
										, tipo			nvarchar(500)
										, data			datetime
										, descrizione	nvarchar(500)
										, data_risposta	datetime
										, risposta		nvarchar(500)
									 );
						insert into #Tb_ric_comloc
									 (
										  contratto  
										, tipo  
										, data  
										, descrizione  
										, data_risposta  
										, risposta  
									 )
                     
						select
								  conloc_codice as contratto
								, er_ricloc_descrizione as tipo
								, er_ricloc_data_richiesta as data
								, er_ricloc_note as descrizione
								, er_ricloc_data_chiusura_ricloc as data_risposta
								, er_ricloc_note_chiusura as risposta
						
						from   #tb_conloc tbc 
								inner join 
								dbo.er_ricloc_richieste_per_locatore
									on 
									er_ricloc_richieste_per_locatore.er_ricloc_conloc_id = tbc.conloc_id
								--inner join 
								--dbo.er_tipric_tipo_richiesta
								--	on 
								--	dbo.er_ricloc_richieste_per_locatore.er_ricloc_tipric_id = dbo.er_tipric_tipo_richiesta.er_tipric_id
								--inner join 
								--dbo.er_tipstr_stato_richiesta
								--	on 
								--	dbo.er_ricloc_richieste_per_locatore.er_ricloc_tipstr_id = dbo.er_tipstr_stato_richiesta.er_tipstr_id
								--inner join 
								--dbo.er_claric_classificazione_richiesta
								--	on 
								--	dbo.er_ricloc_richieste_per_locatore.er_ricloc_claric_id = dbo.er_claric_classificazione_richiesta.er_claric_id;

						 select	  contratto  
								, tipo  
								, data  
								, descrizione  
								, data_risposta  
								, risposta  
						 from   #Tb_ric_comloc;

                     select '<a class="btn btn-secondary float-right" href="/communicate.html?gridName=grid3">Crea comunicazione</a>' as buttons
                          , '{"columns":[{"name":"Codice Contratto","data":"contratto"},{"name":"Tipo comunicazione","data":"tipo"},{"name":"Data comunicazione","data":"data","type":"date"},{"name":"Comunicazione","data":"descrizione"},{"name":"Data risposta","data":"data_risposta","type":"date"},{"name":"Risposta","data":"risposta"}]}' as config, N'Comunicazioni' as title;
                 end;
				
    --THROW 51000, 'not implemented', 1;

    end;


GO

/****** Object:  StoredProcedure [dbo].[aequa_save_data]    Script Date: 17/12/2018 15:31:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description: stored is called by route /api/data result is passed to client - used to store data passed in by user
-- =============================================
CREATE PROCEDURE [dbo].[aequa_save_data] (@xmlInput xml)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	/* input
	<root>
	   <user>
		  <codiceFiscale>a</codiceFiscale>
	   </user>
	   <input>
		  <description>some random description</description>
		  <text>some example text</text>
		  <formName>communication</formName>
	   </input>
	</root>
	*/
	SET NOCOUNT ON;
	
         declare @conloc_id int;
		 declare @codice_fiscale nvarchar(max) = @xmlInput.value(
                                                              '(/root/user/codiceFiscale)[1]'
                                                            , 'nvarchar(max)');

        declare @pathFile as varchar(max) = dbo.F_DETERMINA_PATH_FILE(
                                                'File output' , null);

        select anagra_id
        into   #tb_anagra
        from   dbo.anagra_anagrafica afa
        where  afa.anagra_codice_fiscale = @codice_fiscale;
        select @conloc_id = conloc_id
        from   #tb_anagra ta
               inner join dbo.conloc_contratto_di_locazione cl on cl.conloc_anagra_id = ta.anagra_id
			   where conloc_data_cessazione is null;
		declare @descrizione varchar(1000) = @xmlInput.value(
                                                              '(/root/input/description)[1]'
                                                              ,'varchar(1000)' );
        declare @Testo nvarchar(max) = @xmlInput.value(
                                                        '(/root/input/text)[1]'
														, 'nvarchar(max)');

		insert into ER_RICLOC_richieste_per_locatore
							(
							 er_ricloc_data_richiesta
							,er_ricloc_descrizione
							,er_ricloc_note
							,er_ricloc_conloc_id
							,er_ricloc_anagra_id
							,er_ricloc_aggreg_id
							,er_ricloc_edific_id
							,er_ricloc_uniimm_id
							,er_ricloc_nucfam_id
							)

				select
							  getdate()   
						    , @descrizione                
						    , @Testo   
							, @conloc_id
							, conloc_anagra_id 
							, conloc_aggreg_id 
							, conloc_edific_id 
							, uniloc_uniimm_id 
							, conloc_nucfam_id
				from		conloc_contratto_di_locazione
								inner join uniloc_unita_locativa on conloc_id = uniloc_conloc_id and uniloc_flag_principale = 1 
						where conloc_id = @conloc_id
							;
	--THROW 50001, 'error', 1

	select 'communicazione salvata' as [message];

END

GO

/****** Object:  StoredProcedure [dbo].[aequa_grids]    Script Date: 17/12/2018 15:31:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	stored returns list of grids visible for user
-- =============================================
CREATE PROCEDURE [dbo].[aequa_grids] (@xmlInput xml)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	/* input
	<root>
	   <user>
		  <codiceFiscale>a</codiceFiscale>
	   </user>
	</root>
	*/
	SET NOCOUNT ON;

	(
		SELECT 'Bollette' as title, 'Stampa bollettini' as [description], 'grid1' as gridName
		--UNION
		--SELECT 'Fatture non pagate' as title, 'Visualizza Elenco'/*'Situazione Contabile'*/ as [description], 'grid2' as gridName
		--UNION
		--SELECT 'Incassi' as title, 'Visualizza Elenco'/*'Elenco Versamenti'*/ as [description], 'grid3' as gridName
		--UNION
		--SELECT 'Comunicazioni' as title, 'Visualizza Elenco'/*'Invio comunicazioni ad Aequa Roma'*/ as [description], 'grid4' as gridName
	)
	order by gridName


END

GO


