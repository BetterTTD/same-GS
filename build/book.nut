class SameBook
{
    static c_page = []
        constructor()
        {
        for (local i = 0; i < 19*3; i++)	{ c_page.push(-1); }
        }
    function GetPageID(c_id, opt);
    function NewCompany(c_id);
    function Init();
}

function SameBook.GetPageID(c_id, opt)
{
    if ( c_id < 0 || c_id > 18)     {GS.Log.Error("Damn, dat value sux: "+c_id); return -1; }
    local id_c = c_id * 3;
    if ( c_id > 16 || c_id == 15)   { opt = 0; }
    return SameBook.c_page[id_c + opt];
}

function SameBook.NewCompany(c_id)
{
    if (GSCompany.ResolveCompanyID(c_id) == GSCompany.COMPANY_INVALID)	{ return; }
    local id_c = c_id * 3;
    if (!GSStoryPage.IsValidStoryPage(SameBook.c_page[id_c+0]))
        { SameBook.c_pageage[id_c+0] = GSStoryPage.New(c_id, GSText(GSText.STR_RULES_TITLE)); }
    if (!GSStoryPage.IsValidStoryPage(SameBook.c_page[id_c+1]))
        { SameBook.c_pageage[id_c+1] = GSStoryPage.New(c_id, GSText(GSText.STR_MODERATORS_TITLE)); }
    if (!GSStoryPage.IsValidStoryPage(SameBook.c_page[id_c+2]))
        { SameBook.c_pageage[id_c+2] = GSStoryPage.New(c_id, GSText(GSText.STR_LINKS_TITLE)); }
}

function SameBook.Init()
{
    if (!GSStoryPage.IsValidStoryPage(SameBook.GetPageID(15,0)))
    {
        SameBook.c_page[15 * 3] = GSStoryPage.New(GSCompany.COMPANY_INVALID, GSText(GSText.STR_WELCOME_TITLE));
    }

}
