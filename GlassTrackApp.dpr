program GlassTrackApp;

uses
  System.StartUpCopy,
  FMX.Forms,
  gTrack in 'gTrack.pas' {HeaderFooterForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(THeaderFooterForm, HeaderFooterForm);
  Application.Run;
end.
