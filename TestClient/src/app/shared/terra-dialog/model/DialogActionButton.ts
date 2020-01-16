export class DialogActionButton {
    public BtnCancelTitle: string;
    public BtnOkTitle: string;
    public DisableBtnOk: boolean;

    constructor(options: {
        btnCancelTitle?: string;
        btnOklTitle?: string;
    }={}) {
        this.BtnCancelTitle = options.btnCancelTitle || 'Cancel';
        this.BtnOkTitle = options.btnOklTitle || 'Ok';
    }
}