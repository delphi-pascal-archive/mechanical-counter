unit uCompteurTambours;

interface

                       /////////////////////////////////////////////////
                       //  Compteur mécanique à tambours rotatifs     //
                       //  Conçu sous D6 : novembre 2013              //
                       //             Gilbert GEYER                   //
                       /////////////////////////////////////////////////

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    imgCompteur: TImage;
    bAnimer: TSpeedButton;
    btnAfficherNombre: TSpeedButton;
    Timer1: TTimer;
    Label3: TLabel;
    edNombre: TEdit;
    Label6: TLabel;
    edTimerInterval: TEdit;
    Label1: TLabel;
    edDeltaNombre: TEdit;
    Label2: TLabel;
    imgBrush: TImage;
    procedure FormCreate(Sender: TObject);
    procedure bAnimerClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnAfficherNombreClick(Sender: TObject);
    procedure edTimerIntervalChange(Sender: TObject);
    procedure edDeltaNombreChange(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

var
  WDigit, HDigit, Lg, LgPrec: integer;
  Animer, PremAff: boolean;
  Number, DeltaNombre: Extended;
  Tambour: TBitmap;
  CharPrec: array[0..22] of Char; //< 23 tambours

function clDegradee(Kcl1: single; cl1, cl2: tColor): tColor;
// Renvoie la couleur interpolée entre cl1 et cl2 pour Kcl1 compris entre 0 et 1
var R, G, B: byte;
begin
  R := round(Kcl1 * GetRValue(cl1) + (1 - Kcl1) * GetRValue(cl2));
  G := round(Kcl1 * GetGValue(cl1) + (1 - Kcl1) * GetGValue(cl2));
  B := round(Kcl1 * GetBValue(cl1) + (1 - Kcl1) * GetBValue(cl2));
  Result := RGB(R, G, B);
end;

function BmpTambour(const W, H: integer; cl1, cl2: tColor): tBitMap;
// Renvoie un Bmp avec effet cylindrique pour un tambour
var li, mih: integer; Kcl1: single;
begin
  Result := tBitMap.Create;
  with Result do begin
    width := W; height := H; mih := H shr 1;
    with canvas do begin
      brush.Style := bsClear;
      for li := 0 to Height - 1 do begin
        Kcl1 := abs(li - mih) / mih; 
        pen.Color := clDegradee(Kcl1, cl1, cl2);
        moveTo(0, li); lineTo(width, li);
      end;
      // Séparations verticales et bords :
      Pen.Color := clBlack;
      MoveTo(0, 0); LineTo(0, H);
      MoveTo(0, 0); LineTo(W, 0);
      MoveTo(0, H-1); LineTo(W, H-1);
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
// Initialistions
var
  y, c: Integer;
begin
  HDigit := 48;
  WDigit := 24;
  Tambour := BmpTambour(WDigit, HDigit, clOlive, clWhite);
  with imgCompteur.Canvas do begin
    brush.Color := clWhite; brush.Style := bsSolid;
    FillRect(clipRect);
  end;
  Timer1.Interval := 150;
  edTimerInterval.text := IntToStr(Timer1.Interval);
  PremAff := True;
  Number := -0.1257889002E-4930;
  edNombre.text := FloatToStr(Number);
  btnAfficherNombreClick(Sender);
  DeltaNombre := -81.12E-4930;
  edDeltaNombre.text := FloatToStr(DeltaNombre);
  DoubleBuffered := true;
  panel1.Color := RGB(2, 114, 90);
  Animer := True;
end;

procedure TForm1.bAnimerClick(Sender: TObject);
begin
  Animer := not Animer;
end;

procedure AfficherNombre(var Image: Timage; Nombre: string);
const CF: set of Char = ['+', '-', '.', ',', 'E', 'i'];
var i: integer; CP: char;

  procedure AfficherTambour(Can: TCanvas; IndiceTambour: byte; N: char; PremAffichage: boolean);
  var
    x, y1, y2, y3, d0, th, ic: integer; C: char; nPrec, nSuiv: byte;
    dn, dyn, DeltaT: Cardinal;
  begin
    with Can do begin
      Draw(IndiceTambour * WDigit, 0, Tambour);
      Font.Name := 'Impact';
      Font.Height := 32;
      Font.Style := [fsBold];
      x := (WDigit - TextWidth('0')) div 2;
      x := x + IndiceTambour * WDigit;
      th := TextHeight('0');
      d0 := (HDigit - th) div 2;
      y1 := d0;
      Brush.Style := bsClear;
      if (N in CF) then Font.Color := clRed else Font.Color := clBlack;
      pen.Color := clBlack;
      if PremAffichage or (N in CF) or (CP in CF) or (CP = #47) then begin
        TextOut(x, y1, N); CharPrec[IndiceTambour] := N;
        EXIT;
      end;
      if (N = CP) then EXIT // Pas de changement : on passe
      else begin
        nPrec := Ord(CP); nSuiv := Ord(N);
        dn := abs(nPrec - nSuiv) + 1;
        DeltaT := Form1.Timer1.Interval div dn;
        DeltaT := round(DeltaT * 0.75);
        dyn := HDigit div dn;
        y1 := 0;
        if CP < N then begin
          for C := CP to N do
          begin
            ic := Ord(C);
            Draw(IndiceTambour * WDigit, 0, Tambour);
            TextOut(x, y1, C);
            y2 := y1 + th + d0;
            MoveTo(IndiceTambour * WDigit, y2);
            LineTo((IndiceTambour + 1) * WDigit, y2);
            y3 := y1 + HDigit;
            if C > CP then TextOut(x, y3, chr(ic - 1));
            Form1.imgCompteur.Repaint;
            sleep(DeltaT);
            dec(y1, dyn);
          end;
        end else begin
          y1 := 0;
          for C := CP downto N do
          begin
            ic := Ord(C);
            Draw(IndiceTambour * WDigit, 0, Tambour);
            TextOut(x, y1, C);
            y2 := y1 - d0;
            MoveTo(IndiceTambour * WDigit, y2);
            LineTo((IndiceTambour + 1) * WDigit, y2);
            y3 := y1 - HDigit;
            if C < CP then TextOut(x, y3, chr(ic - 1));
            Form1.imgCompteur.Repaint;
            sleep(DeltaT);
            inc(y1, dyn); ;
          end;
        end;
      end;
      // Recouvrement pour ajuster les alignements :
      y1 := d0;
      Draw(IndiceTambour * WDigit, 0, Tambour);
      Font.Color := clBlack;
      TextOut(x, y1, N);
      CharPrec[IndiceTambour] := N;
    end;
  end;

begin
  if Nombre = '' then exit;
  Lg := length(Nombre);
  Image.Width := Lg * WDigit;
  if PremAff then begin
    for i := 0 to 22 do begin
      CharPrec[i] := #47;
      if (i >= 1) and (i <= length(Nombre)) then AfficherTambour(Image.Canvas, i - 1, Nombre[i], TRUE); //i-1 = IndiceTambour
    end;
    LgPrec := Lg; PremAff := false;
    EXIT;
  end;
  if Lg < LgPrec then begin // R.à.z des tambours excédentaires
    for i := Lg to LgPrec do begin
      CharPrec[i] := #47;
    end;
  end;
  for i := Lg downto 1 do begin
    CP := CharPrec[i - 1];
    if CP = Nombre[i] then Continue; // Pas de changement : on passe
    AfficherTambour(Image.Canvas, i - 1, Nombre[i], FALSE); // i-1 = IndiceTambour
  end;
  LgPrec := Lg;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if Animer then begin
    Number := Number + DeltaNombre;
    edNombre.Text := FloatToStr(Number); edNombre.Update;
    AfficherNombre(imgCompteur, edNombre.Text);
  end;
end;

procedure TForm1.btnAfficherNombreClick(Sender: TObject);
var po: integer; s: string;
begin
  s := edNombre.text;
  po := pos('e', s);
  if po > 0 then begin s[po] := 'E'; edNombre.Text := s; end;
  Number := StrToFloat(edNombre.text);
  AfficherNombre(imgCompteur, edNombre.text);
end;

procedure TForm1.edTimerIntervalChange(Sender: TObject);
begin
  if (edTimerInterval.text = '') or (edTimerInterval.text = '0')
    then begin edTimerInterval.text := IntToStr(1); edTimerInterval.Update; end;
  Timer1.Interval := StrToIntDef(edTimerInterval.text, 1);
end;

procedure TForm1.edDeltaNombreChange(Sender: TObject);
var po: integer; s: string;
begin
  s := edDeltaNombre.text;
  po := pos('e', s);
  if po > 0 then begin s[po] := 'E'; edDeltaNombre.Text := s; end;
  DeltaNombre := StrToFloatDef(edDeltaNombre.Text, 1.0);
end;

procedure TForm1.FormPaint(Sender: TObject);
begin
  Canvas.Brush.Bitmap := imgBrush.Picture.Bitmap;
  Canvas.FillRect(Canvas.ClipRect);
  Canvas.Brush.Bitmap := nil;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   Tambour.Free;
end;

end.

