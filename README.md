[![REUSE status](https://api.reuse.software/badge/github.com/SAP-samples/cloud-abap-exchange-rates)](https://api.reuse.software/info/github.com/SAP-samples/cloud-abap-exchange-rates)

# Description
This example code helps loading currency exchange rates from the European Central Bank into an SAP Cloud Platform, ABAP environment system for utilization in the currency conversion functionality. 

## Prerequisites

To use this sample code you need to have access to an SAP Cloud Platform, ABAP environment system with approriately set up ABAP Development Tools (ADT), including abapGit for import of this repository. Also you need a target package to load the code of this repository into.

## Import in ADT

To use this repository, please import it in ADT via the Project Explorer perspective in the corresponding abapGit Repositories view. Link a new abapGit Repository via this repository's https clone link. Select the master branch (leave the default) and name your target package to pull into. Choose "pull after link" to get the code with finishing the linking activity.

## Use

This repository contains two ABAP classes that show two different options on how to load daily currency exchange rates provided by the European Central Bank (ECB) into the corresponding customizing table of the ABAP system. One class retrieves currency exchange rates from the ECB's own XML API and another the same from a JSON API provided by Madis Väin. Retrieved content of both retrieval methods is the same.

Note that retrieving ECB data is just an example; there are other central banks or services that provide different or enhanced data on exchange rates for which the retrieval needs to be altered appropriately, with respect to service link and format, of course.

The classes perform the exchange rate retrieval, convert the retrieved data into the internal storage format and write it to the currency rate customizing table using the respective API class CL_EXCHANGE_RATES (available with the SAP Cloud Platform, ABAP environment 2008 release). On execution as "console app" (by pressing F9) the ABAP console shows the retrieved data in its storage format and provides notice on write. Note that appropriate write authorization must be supplied to actually perform the customizing update (see the classes' source code for details - a corresponding tester role containing the required authorization is supplied with the system deployment).

Idea is to encapsulate the currency exchange rate retrieval into an own application job that updates the exchange rates on a daily basis. This should be organized with respect to own demands and boundary conditions.

## Utilization

These example classes (you just need one, of course) provide currency exchange rates to the currency rate type 'EURX' which is a "standard exchange rate type" provided in the regular system deployment of an SAP Cloud Platform, ABAP environment system (on how to customize exchange rate handling in general is subject to another story). When used correctly, you are able to utilize the CDS function currency_conversion with the "right" exchange rates.

      @EndUserText.label: 'Price (in US American Dollars)'
      currency_conversion(
        client => client,
        amount => amount,
        round => '',
        source_currency => currency,
        target_currency => cast('USD' as abap.cuky),
        exchange_rate_type => cast('M' as abap.char(4)),
        exchange_rate_date => cast($session.system_date as abap.dats)
                         ) as PriceInUSD

Note: Exchange rate type 'EURX' and 'M' match in the standard customizing.

## Limitations

This sample code sits on top a dedicated service provided by the European Central Bank; as such only the data provided from here is reflected. This is, as written, exemplary for the general way on how to obtain currency exchange rates. As such, the implementation is "as is" without the claim to solve the complete variety of currency conversion issues. With that respect please raise a ticket to SAP to get a "standard" answer.

## Known Issues

Please note that write authorization on view V_TCURR must be supplied using authorization object "S_TABU_NAM"; this is solved in the standard deployment by a corresponding tester role; without this any write attempt will be refused. The ABAP console output will show a respective notification.

## How to obtain support

This code is "as is" and shall provide an idea on what to do. If you find a "real" issue with "this" implementation, then raise an issue in this Github repository.

## Contributing

With the state "as is" actually no contribution is intended; but as usual on Github, please feel free to clone this repository and use it for your own benefit.

## License

Copyright (c) 2020 SAP SE or an SAP affiliate company. All rights reserved. This project is licensed under the Apache Software License, version 2.0 except as noted otherwise in the [LICENSE](LICENSE) file.

