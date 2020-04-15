/*Post Funding Renewals 1*/

Select 
C.Id as ContactId,
A.Id as AccountId,
O.Id as OppId, 
F.Id as FundingOfferId,
C.Email,
C.FirstName, 
C.Activated_Date__C as ActivatedDate,
A.Name as AccountName, 
A.New_Renewal_Rep__c as OppRenewalRepId,
A.Funded_Advances__c as FundedAdvances,
O.Type as OppType,
O.StageName as OppStageName,
O.New_Renewal_Rep__c as OppRenewalRepName,
O.Renewal_Rep_Email__c as OppRenewalRepEmail,
O.Renewal_Rep_Phone__c as OppRenewalRepPhone,
O.[Exclude_from_Email_Updates__c] as OpportunityExcludefromEmailUpdates,
F.Pct_Pace__c as FundingOfferPacePercentage,
F.Pct_Paid__c as FundingOfferPercentPaid,
F.Stacking_Alert__c as FundingOfferStackingAlert,
F.Funding_Source__c as FundingOfferFundingSource,
F.Cancel_Renewal_Emails__c as FundingOfferCancelRenewalEmails,
F.Status__c as FundingOfferStatus,
F.Renewal_Emails_Sent__c as FundingOfferRenewalEmailsSent,
S.Name as FundingSourceName

from Contact_Salesforce C 
Inner JOIN Account_Salesforce A ON C.Accountid = A.id 
Inner JOIN Opportunity_Salesforce O ON O.Accountid = A.id 
Inner JOIN Funding_Offer__c_Salesforce F ON O.Id = F.Opportunity__c
Inner JOIN Funding_Source__c_Salesforce S ON F.Funding_Source__c = S.Id
/* Make sure we dont send a Contact/Opportunity through the Journey again if theyve already entered
	in the Pct_Paid__c range that its currently in. PaidRange in the Journey log is the max of the
	Pct_Paid__c that theyve entered the Journey with, so we make sure the Pct_Paid__c has exceeded
	that range in order to let them enter. The LEFT JOIN makes sure that we whether there is or
	isnt a record in the log, a record will still be returned. We couple this with the AND
	L.ContactId is null in the WHERE statement so that if this LEFT JOIN returns a record, that
	means this Contact/Opportunity has already been through the Journey for that PaidRange. */
LEFT JOIN PostFundingJourney_Log_Copy L ON C.ID = L.ContactId and O.ID = L.OppId and F.Pct_Paid__c <= L.PaidRange

Where (O.Type) = 'Renewal'
AND COALESCE(O.StageName, '') = 'Funded' 
AND COALESCE(F.Pct_Pace__c, 0.00) >= 85.00
AND COALESCE(F.Pct_Paid__c, 0.00) >= 25
AND F.Stacking_Alert__c is Null
AND A.Funded_Advances__c = 2
AND Email is not null
AND COALESCE(F.Cancel_Renewal_Emails__c,'') = 0
AND COALESCE(F.Status__c,'') = 'ACT'
AND COALESCE(O.[Exclude_from_Email_Updates__c],'') = 0
AND COALESCE(S.Name, '') like '%MCA%'
AND O.CreatedDate >= '1/1/2018'
AND NOT COALESCE(F.Renewal_Emails_Sent__c, '') LIKE 
    CASE when F.Pct_Paid__c <= 39.99 then '%25%'
        when F.Pct_Paid__c <= 59.99 then '%50%'
        when F.Pct_Paid__c <= 69.99 then '%60%'
        when F.Pct_Paid__c <= 79.99 then '%70%'
        when F.Pct_Paid__c <= 89.99 then '%80%'
        when F.Pct_Paid__c <= 99.99 then '%90%'
        else '%100%'
    end