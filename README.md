# emetra
Low-level libraries and components from **FastTrak** application.  Existing code that has passed peer review will be moved here.  
The decision to do so will be based on a set of critera:

## The code ...

1. Is used by **FastTrak** and/or related tools
2. Has functionality that is general in nature, or can be useful to other teams.
3. Has a quality that we are at least **happy** with, if not proud of (as opposed just satisfied).
4. Is well documented with XML style comments and references.
5. Does not contain secrets of any kind (passwords, usernames, API-keys etc).
6. Has passed review from at least two members of our team, where items 1-5 are addressed.

## Documentation

To determine what it means to be "well documented", these guidelines should be kept in mind:

* The purpose of a unit itself should be documented.
* References to principles, implementation patterns etc. should be included.
* Use XML documentation, but keep your focus in the interface section of a unit.
* Document all methods and properties accessible from outside a class.
	* This means that propery accessors should not be documented individually, only the properties themselves.
* Use standard documentation style in implementation section: 
	* `// Single line comment` 
	* `/* Multiline comment */`
* The documentation in the interface section should be done with a tool that supports references. 
like [Documentation Insight](http://www.devjetsoftware.com/products/documentation-insight/ "Documentation Insight") 
from [DevJet Software](http://www.devjetsoftware.com/ "DevJet software").

# Coding style

All code shoule have a uniform style, and the coding style should be the best style we can come up with.
These is what we currently believe in:

## Naming things

Follow naming standards from **Delphi** libraries and the style defined in 
[Object Pascal Style guide](http://edn.embarcadero.com/print/10280 "Object Pascal Style Guide"), 
but this is hard and nobody gets it quite right: 

> There are only two hard things in Computer Science: cache invalidation and naming things.
> 
> -- Phil Karlton
  
We have done some minor changes to the general rules outlined in the document above.
They are all in an effort to improve readability and to communicate intent more clearly.
Some of them are put in place because times change, and the capabilities of the Delphi compiler change with them.

### Units 

We follow standards that are common in the .NET world (and probably other worlds as well):

* Use dot notation when naming units, going from the general to the more specific after each dot.  
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
* Make then private almost without exception, strict private and protected are the only other options.
* Communicate intent by making the setters use a const (only exception is indexed properties, where the compiler won't allow it).  
* If you need to override a property accessor in a descendant class, think twice before making it protected.

See example below.

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

The reasoning behind this change is that it should "hurt" to use a property accessor directly. You should know immediately that this is not how
you are supposed to use this value. Property accessors are
 
### Method arguments

Always use A as a prefix for arguments, with **only one exception**. Is acceptable to use `Sender: TObject`, because **Sender** is almost never seen as a property name.
Observe that using `Value` as a parameter name is not acceptable, as **Value** is not an uncommon property name, thus leading to unwanted confusion.

### Constants

Constants of all types are named with uppercase letters and underscores, but always starting with a letter. 
This includes constant arrays, but not resourcestrings (they are not true constants).

### Local variables
Local variables should have names in `camelCase`.  This makes them easy to distinguish from method arguments and class properties.  

## Grouping and ordering

* Fields should be s**trict private,** property accessors **private**.  This may not be necessary from a functional standpoint, but it allows us to
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
