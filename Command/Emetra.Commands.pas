/// <summary>
///   General commands should be added here, to allow client and receiver to
///   share the same set of parameter names for commands.
/// </summary>
unit Emetra.Commands;

interface

const
  /// <summary>
  ///   A general command used to request for a paper copy of some object,
  ///   usually associated with a file name. There could be a preview of the
  ///   file as well, this is left to the implementor of the command.
  /// </summary>
  CMD_PRINT    = 'Print';

  /// <summary>
  ///   Parameter that should be used for print commands if the request is tied
  ///   to a specific file to be printed.
  /// </summary>
  PRM_FILE_NAME = 'FileName';

implementation

end.
