# emetra
Low-level Delphi libraries and components from **FastTrak** application.  As of April 18th 2020, this contains a few selected interfaces and classes as a starting point. 

We will move more code into this repository over time, based on an evolving set of criteria:

## The code ...

1. Is used by **FastTrak** and/or related tools.
2. Has functionality that is general in nature, or can be useful to other teams.
3. Has a quality that we are at least **happy** with, if not proud of.
4. Is well documented with XML style comments and references.
5. Does not contain secrets of any kind (passwords, usernames, API-keys etc).
6. Has passed review from at least two members of our team, where criteria 1-5 are addressed.

## Documentation

To determine what it means to be "well documented", these guidelines should be kept in mind:

* The purpose of a unit itself should be documented.
* References (and hyperlinks) to design principles, implementation patterns etc. should be included if relevant.
* Use XML documentation, but keep most of the documentation in the interface section of a unit.
* Document all methods and properties accessible from outside a class.
* Do not document propery accessors should individually, only the properties themselves.
* Use standard (simplified) documentation style in implementation section: 
	* `// Single line comment` 
	* `/* Multiline comment */`
* The documentation in the interface section should be done with a tool that supports references. 
like [Documentation Insight](http://www.devjetsoftware.com/products/documentation-insight/ "Documentation Insight") 
from [DevJet Software](http://www.devjetsoftware.com/ "DevJet software").

# Quality

This is an evolving list.  The code should as a rule:

* Not produce any hints or warnings from the most recent Delpphi compiler, currently Delphi 10.3. Rio.
* Keep the "uses" clause to a minumum, not include units that are not actually in use.
* Be cross-platform whenever that will be a minor investment.

# Coding style

All code should have a uniform style, and the coding style should be the best style we can come up with.
This is an outline of what we currently believe is the best style.  It 

## Naming things

Follow naming standards from **Delphi** libraries and the style defined in 
[Object Pascal Style guide](http://edn.embarcadero.com/print/10280 "Object Pascal Style Guide"), 
but this is hard and nobody gets it quite right (in other people's minds).  We have done some minor changes to the general 
rules outlined in the document above.  They are all in an effort to improve readability and to communicate intent more clearly.
Some of them are added because times change, and the capabilities of the Delphi compiler changes as well.

> There are only two hard things in Computer Science: cache invalidation and naming things.
> 
> -- Phil Karlton

### Units 

We follow standards that are common in the .NET world (and probably other worlds as well):

* Use dot notation when naming units, going from the general to the more specific after each dot.
* Avoid more than three sections to a name, at most four.  
* Use subfolders for functional areas or subsystems.  
* The names of the files in subsystems should generally reflect the file path.
* It is acceptable to put small utility classes together in a **Utils** folder, in order keep library paths manageable.
  
**Example:** A unit in the **LabData** subsystem of an electronic patient record (EPR) is placed in the **EPR\LabData** subfolder.  
The unit file should then start with `EPR.LabData.`.  


### Property accessors

Property accessors should follow these rules:

* List them together under a heading `{ Property accessors }`, 
* Use a single underscore after **Set** and **Get**, followed by the exact name of the property they access.
* Ordered them alphabetically, with getters before setters (as would also follow from the alphabetical order).
* Make them private almost without exception, strict private and protected are your only other options.
* Communicate intent by making the setters use a const (only exception is indexed properties, where the compiler won't allow it).  
* If you need to override a property accessor in a descendant class, think twice before making it protected.

See example code below that illustrates some best practices:

    TMyClass = class( TObject )
	strict private
       fLastError: string;
    private
      { Property accessors }
      function Get_ApiKey: string;
      procedure Set_ApiKey( const AValue: string );
    public
	  { Initialization }
      constructor Create; reintroduce;
      procedure AfterConstruction; override;
      procedure BeforeDestruction; override;
      { Public declarations }
      function TryGetFormOrders( const AFormOrderStatus: string ): boolean;
      function TryPostFormOrder( out AResponse: IDipsPromsOrderResponse ): boolean;
      function TryPutFormData( const ARequest: IDipsPromsDataUpdateRequest; out AResponse: IDipsPromsOrderResponse ): boolean;
      { Properties }
      property ApiKey: string read Get_ApiKey write Set_ApiKey;
      property LastError: string read fLastError;
    end;

The reasoning behind using the unusual style `Get_PropertyName` is that it should "hurt" to use a property accessor directly. 
You should know immediately that this is not how you are supposed to use it, simply because writing the code feels awkward.
 
### Method arguments

Always use a captial "A" as a prefix for arguments, with **only one exception**. Is acceptable to use `Sender: TObject`, because **Sender** is almost never seen as a property name.
Observe that using `Value` as a parameter name is not acceptable, as **Value** is not an uncommon property name, thus leading to unwanted confusion.

### Constants

Constants of all types are named with uppercase letters and underscores, but always starting with a letter. 
This includes constant arrays, but not resourcestrings (they are not true constants).

### Local variables

Local variables should have names in `camelCase`.  This makes them easy to distinguish from method arguments and class properties.  

## Grouping and ordering

* Fields should be **strict private,** property accessors **private**.  This may not be necessary from a functional standpoint, but it allows us to
use language structures for grouping in a nice way.  
* Sort the fields alphabetically, except when a functional grouping seems more appropriate (typically if there is a large number of fields).  
* If functional grouping is used, use comments as headers between the groups.
* Keep constructors and destructors together directly after the **public** keyword, under a comment { Initialization }, see code example above.
* Components should be ordered alphabetically, and they should always have p  

### Components

A component should be given a name that reflects its purpose.  It is common practice to use hungarian notation for components, even though
this is not what the IDE suggests.  We always use hungarian notation for components, like this:

* lblFirstNameHeader
* edtFirstName
* btnSubmitOk
  
Do not use names like Label1, Edit1 etc., these are no better than "magical numbers".  For renaming, use refactor method by right-clicking in the source code.  
This will rename all occurences in code and in declarations, as opposed to renaming components in the object inspector.
