require("version.nut");

class SameGS extends GSController {
    constructor(){}
}

function SameGS::Start() {
    GSController.Sleep(1);
    delay = true;
    while (delay) {
        for (local i = 0; i < 15; i++) {
            if (GSCompany.ResolveCompanyID(i) != GSCompany.COMPANY_INVALID) {
                delay = false;
                GSLog.Info("Company found.");
            }
        }
    }
    GSStoryPage.Show(CompanyLayer.GetPageID(15, 0));
}
